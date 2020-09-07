#!/usr/bin/env bash
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(pwd)
popd > /dev/null

CONNECT_REST_API_URL=${CONNECT_REST_API_URL:-http://localhost:8083}
KAFKA_BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:19092}"
KAFKA_CONFIGS_CMD="${KAFKA_CONFIGS_CMD:-$(which kafka-configs || which kafka-configs.sh || echo "")}"

function log () {
    local level="${1:?Requires log level as first parameter!}"
    local msg="${2:?Requires message as second parameter!}"
    echo -e "$(date --iso-8601=seconds)|${level}|${msg}"
}

function wait_until_available () {
    while [ $(curl -s -L -o /dev/null -w %{http_code} --max-time 60 ${CONNECT_REST_API_URL}) -ne 200 ]; do echo -n "."; sleep 2; done
}

function determine_default_replica_count () {
    ${KAFKA_CONFIGS_CMD} --bootstrap-server ${KAFKA_BOOTSTRAP_SERVER} --entity-type brokers --all --describe \
        | grep default.replication.factor \
        | sed -e 's/^[[:space:]]*//' \
        | cut -d ' ' -f 1 \
        | cut -d '=' -f 2
}

function replace_replica_count_in_connectors_config () {
    local json="${1:?Requires json as first parameter!}"
    local replicas="$(determine_default_replica_count)"
    if [ ! -z "${replicas}" ] && [ ! -z "$(echo "${json}" | jq -r '."confluent.topic.replication.factor" | values')" ]; then
        echo "${json}" | jq --argjson replicas 1 '."confluent.topic.replication.factor"=$replicas'
    else
        echo "${json}"
    fi
}

function deploy_connector () {
    local configfile=${1:?Requires filename as first parameter!}
    local connectorname=$(jq -r .name ${configfile})
    local json="$(replace_replica_count_in_connectors_config "$(jq .config ${configfile})")"
    curl -s -w "\n%{http_code}" --max-time 60 -X PUT -H "Content-Type: application/json" -d "${json}" ${CONNECT_REST_API_URL}/connectors/${connectorname}/config
}

function query_connector_state () {
    local configfile=${1:?Requires filename as first parameter!}
    local connectorname=$(jq -r .name ${configfile})
    curl -s -w "\n%{http_code}" --max-time 60 -X GET -H "Content-Type: application/json" ${CONNECT_REST_API_URL}/connectors/${connectorname}/status
}

function deploy_connector_in_file () {
    local file=${1:?Requires filename as first parameter!}
    local filebasename="$(basename "${file}")"
    local response="$(deploy_connector "${file}")"
    local body=$(echo "${response}" | cut -d$'\n' -f1)
    local http_code=$(echo "${response}" | cut -d$'\n' -f2)
    if [[ "${http_code}" =~ ^2.* ]]; then
        local connectorname="$(echo "${body}" | jq -r .name)"
        local connectortype="$(echo "${body}" | jq -r .type)"
        local status_response="$(query_connector_state "${file}")"
        local status=$(echo "${status_response}" | cut -d$'\n' -f1)
        local status_http_code=$(echo "${status_response}" | cut -d$'\n' -f2)
        local retries=0
        while [[ ! "${http_code}" =~ ^2.* ]] || [ "$(echo "${status}" | jq -r '.connector')" == "null" ] || [ "$(echo "${status}" | jq -r '.connector | .state')" == "UNASSIGNED" ] && [ ${retries} -lt 10 ]; do
            sleep 1
            status="$(query_connector_state "${file}" | cut -d$'\n' -f1)"
            let "retries++"
        done;
        log "INFO" "Installed or updated ${connectortype} connector '${connectorname}' from ${filebasename} in Kafka Connect:\n$(echo "${status}" | jq '.connector')"
    else
        log "ERROR" "Could not deploy ${filebasename} to Kafka Connect:\n$(echo "${body}" | jq '.')"
        return 1
    fi
}

function deploy_connectors_in_dir () {
    local configdir=${1:?Requires dir as first parameter!}
    local return_code=0;
    for file in $(find "${configdir}" -name "*.json" | sort); do
        deploy_connector_in_file "${file}"
        if [ $? -ne 0 ]; then
            return_code=1
        fi
    done
    return ${return_code}
}

function main () {
    log "INFO" "Start Connectors deployment to ${CONNECT_REST_API_URL}."
    wait_until_available
    local target="${1:-${SCRIPT_DIR}}"
    if [ -d "${target}" ]; then
        deploy_connectors_in_dir "${target}"
    else
        deploy_connector_in_file "${target}"
    fi
}

main "$@"