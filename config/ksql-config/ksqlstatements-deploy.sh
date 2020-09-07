#!/usr/bin/env bash
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(pwd)
popd > /dev/null

KSQL_REST_API_URL=${KSQL_REST_API_URL:-http://localhost:8088}

_commandSequenceNumber=""

function log () {
    local level="${1:?Requires log level as first parameter!}"
    local msg="${2:?Requires message as second parameter!}"
    echo -e "$(date --iso-8601=seconds)|${level}|${msg}"
}

function wait_until_available () {
    while [ $(curl -s -L -o /dev/null -w %{http_code} --max-time 60 ${KSQL_REST_API_URL}/info) -ne 200 ]; do echo -n "."; sleep 2; done
}

function deploy_ksqstatement () {
    local file=${1:?Requires filename as first parameter!}
    local ksqlJson="$(jq --argjson commandSequenceNumber ${_commandSequenceNumber:-null} '. + {commandSequenceNumber: $commandSequenceNumber}' "${file}")"
    curl -s -w "\n%{http_code}" --max-time 60 -X POST -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -d"${ksqlJson}" ${KSQL_REST_API_URL}/ksql
}

function deploy_ksqstatement_in_file () {
    local file="${1:?Requires filename as first parameter!}"
    local filebasename="$(basename "${file}")"
    local response="$(deploy_ksqstatement "${file}")"
    local body=$(echo "${response}" | cut -d$'\n' -f1)
    local http_code=$(echo "${response}" | cut -d$'\n' -f2)
    if [[ "${http_code}" =~ ^2.* ]]; then
        _commandSequenceNumber="$(echo "${body}" | jq -r '. | last | .commandSequenceNumber | values')"
        log "INFO" "Deployed ${filebasename} to ksqlDB (seq=${_commandSequenceNumber}):\n$(echo "${body}" | jq '.[] |= del(.statementText)')"
    else
        local error_code="$(echo "${body}" | jq -r .error_code)"
        local message="$(echo "${body}" | jq -r .message)"
        if [[ "${error_code}" == "40001" ]] && [[ "${message}" =~ "same name already exists" ]]; then
            log "INFO" "Statement in ${filebasename} already exists: ${message}"
        elif [[ "${error_code}" == "40002" ]]; then
            log "WARNING" "File ${filebasename} contains a statement, that should be issued to /query endpoint: ${message}"
        else
            log "ERROR" "Could not deploy ${filebasename} to ksql:\n$(echo "${body}" | jq '.')"
            return 1
        fi
    fi
}

function deploy_ksqlstatements_in_dir () {
    local configdir=${1:?Requires dir as first parameter!}
    for file in $(find "${configdir}" -name "*.json" | sort); do
        deploy_ksqstatement_in_file "${file}"
        if [ $? -ne 0 ]; then
            log "ERROR" "Abort processing of further requests!"
            return 1
        fi
    done
}

function main () {
    log "INFO" "Start Ksql statement deployment to ${KSQL_REST_API_URL}."
    wait_until_available
    local target="${1:-${SCRIPT_DIR}}"
    if [ -d "${target}" ]; then
        deploy_ksqlstatements_in_dir "${target}"
    else
        deploy_ksqstatement_in_file "${target}"
    fi
}

main "$@"