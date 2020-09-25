#!/usr/bin/env bash
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(pwd)
popd > /dev/null

NODERED_REST_API_URL=${NODERED_REST_API_URL:-http://localhost:1880}

function log () {
    local level="${1:?Requires log level as first parameter!}"
    local msg="${2:?Requires message as second parameter!}"
    echo -e "$(date --iso-8601=seconds)|${level}|${msg}"
}

function wait_until_available () {
    while [ $(curl -s -o /dev/null -w %{http_code} ${NODERED_REST_API_URL}/flows) -ne 200 ]; do echo -n "."; sleep 2; done
}

function deploy_flow () {
    local file="${1:?Requires filename as first parameter!}"
    curl -s -w "%{http_code}" -o /dev/null --max-time 60 -X POST -H "Content-Type: application/json" -d@"${file}" ${NODERED_REST_API_URL}/flows
}

function deploy_flows_in_file () {
    local file="${1:?Requires filename as first parameter!}"
    local filebasename="$(basename "${file}")"
    local http_code="$(deploy_flow "${file}")"
    if [[ "${http_code}" =~ ^2.* ]]; then
        log "INFO" "Deployed flow in file ${filebasename} to Node Red (HTTP ${http_code})."
    else
        log "ERROR" "Could not deploy flow in file ${filebasename} to Node Red (HTTP ${http_code})."
        return 1
    fi
}

function deploy_flows_in_dir () {
    local configdir=${1:?Requires dir as first parameter!}
    local return_code=0;
    for file in $(find "${configdir}" -name "*.json" | sort); do
        deploy_flows_in_file "${file}"
        if [ $? -ne 0 ]; then
            return_code=1
        fi
    done
    return ${return_code}
}

function main () {
    log "INFO" "Start Node Red flow deployment to ${NODERED_REST_API_URL}."
    wait_until_available
    local target="${1:-${SCRIPT_DIR}}"
    if [ -d "${target}" ]; then
        deploy_flows_in_dir "${target}"
    else
        deploy_flows_in_file "${target}"
    fi
}

main "$@"