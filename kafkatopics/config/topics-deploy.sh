#!/usr/bin/env bash
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(pwd)
popd > /dev/null

KAFKA_BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:19092}"
KAFKA_TOPICS_CMD="${KAFKA_TOPICS_CMD:-$(command -v kafka-topics || command -v kafka-topics.sh || echo "")}"

function log () {
    local level="${1:?Requires log level as first parameter!}"
    local msg="${2:?Requires message as second parameter!}"
    echo -e "$(date --iso-8601=seconds)|${level}|${msg}"
}

function wait_until_available () {
    while [ -z "$(timeout 60 ${KAFKA_TOPICS_CMD} --bootstrap-server ${KAFKA_BOOTSTRAP_SERVER} --describe --topic _confluent-license | grep '_confluent-license.*Isr: [0-9,]\+.*Offline: *$')" ]; do 
        echo -n "."; sleep 2; 
    done
}

function deploy_topic () {
    local definition="${1:?Requires json definition for topic as first parameter!}"
    local topicname="$(echo "${definition}" | jq -r '.topic | values')"
    local partitions="$(echo "${definition}" | jq -r '.partitions | values')"
    local replicationFactor="$(echo "${definition}" | jq -r '.replicationFactor | values | " --replication-factor "+(.|tostring)')"
    local configs="$(echo $topic | jq -r '.configs | values | .[] | " --config "+.' | tr -d '\n')"
    timeout 60 ${KAFKA_TOPICS_CMD} --bootstrap-server "${KAFKA_BOOTSTRAP_SERVER}" --create \
        --topic "${topicname:?Topic name missing!}" \
        --partitions "${partitions:-6}" \
        ${replicationFactor} \
        ${configs} 2>&1
}

function deploy_topics_in_file () {
    local file=${1:?Requires filename as first parameter!}
    local filebasename="$(basename "${file}")"
    log "INFO" "Start deployment of topics in ${filebasename}."
    local return_code=0;
    while read topic; do
        local enabled=$(echo "${topic}" | jq -r '.enabled | values')
        if [ "${enabled}" == "false" ]; then
            log "INFO" "Deployment of topic disabled: ${topic}"
            continue;
        fi
        local response="$(deploy_topic "${topic}")"
        if [[ "${response}" =~ "Created topic" ]]; then
            log "INFO" "Deployed Topic to Kafka: ${topic}"
        elif [[ "${response}" =~ "already exists" ]]; then
            log "INFO" "Topic already exists: ${topic}"
        elif [[ "${response}" =~ "Broker may not be available" ]]; then
            log "ERROR" "Could not deploy topic to ${KAFKA_BOOTSTRAP_SERVER}, because broker is not available: ${topic}"
            return_code=1
        else
            log "ERROR" "Could not deploy ${topic}:\n${response}"
            return_code=1
        fi
    done < <(jq -rc '.topics[]' ${file})
    return ${return_code}
}

function deploy_topics_in_dir () {
    local configdir=${1:?Requires dir as first parameter!}
    local return_code=0;
    for file in $(find "${configdir}" -name "*.json" | sort); do
        deploy_topics_in_file "${file}"
        if [ $? -ne 0 ]; then
            return_code=1
        fi
    done;
    return ${return_code}
}

function main () {
    log "INFO" "Start topic deployment to ${KAFKA_BOOTSTRAP_SERVER}."
    if [ -z "${KAFKA_TOPICS_CMD}" ]; then
        log "ERROR" "kafka-topics command not found!"
        return 1
    fi
    wait_until_available
    local target="${1:-${SCRIPT_DIR}}"
    if [ -d "${target}" ]; then
        deploy_topics_in_dir "${target}"
    else
        deploy_topics_in_file "${target}"
    fi
}

main "$@"