#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
EMOB_DC_DIR=$(pwd)
popd > /dev/null

DC_INFRA_CURRENT_FILE=".emob-dc-infra"

DC_INFRA_DEFAULT="docker-compose.yaml"
DC_INFRA_HA="docker-compose.infra-ha.yaml"
DC_INFRA_SINGLE="docker-compose.infra-single.yaml"

DC_DEPLOY="docker-compose.deploy.yaml"
DC_TESTDATA="docker-compose.testdata.yaml"
DC_CLI="docker-compose.cli.yaml"

DOCKER_LOG_LEVEL="${DOCKER_LOG_LEVEL:-"ERROR"}"

_context="all" # 'all', 'infra', 'deploy', 'testdata' or 'cli'

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    log "INFO" "** Trapped CTRL-C: Stopping execution"
    exit 0
}

function fail () {
    log "ERROR" "$1"
    exit 1
}

function log () {
    local level="${1:?Requires log level as first parameter!}"
    local msg="${2:?Requires message as second parameter!}"
    echo -e "$(date --iso-8601=seconds)|${level}|${msg}"
}

function determine_dc_infra_file () {
    cat "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}" 2>/dev/null || echo ${DC_INFRA_DEFAULT}
}

function determine_dc_files () {
    if [ "${_context}" == "infra" ]; then
        determine_dc_infra_file
    elif [ "${_context}" == "deploy" ]; then
        echo ${DC_DEPLOY}
    elif [ "${_context}" == "testdata" ]; then
        echo ${DC_TESTDATA}
    elif [ "${_context}" == "cli" ]; then
        echo ${DC_CLI}
    else
        echo "$(determine_dc_infra_file) ${DC_DEPLOY} ${DC_TESTDATA} ${DC_CLI}"
    fi
}

function dc_in_env () {
    docker-compose --log-level "${DOCKER_LOG_LEVEL}" --project-directory "${EMOB_DC_DIR}" $(for file in $(determine_dc_files); do echo "-f ${file}"; done) "$@"
}

function run_job () {
    local service="${1:?Require service as first parameter!}"
    log "INFO" "Starting job ${service}"
    _context="all"
    until dc_in_env up --exit-code-from "${service}" "${service}"; do
        log "INFO" "${service} execution failed. Retry..."
    done
}

function start_services () {
    log "INFO" "Starting services $*"
    _context="all"
    dc_in_env up --no-recreate -d $@
}

function stop_services () {
    log "INFO" "Stopping and removing services $*"
    _context="all"
    dc_in_env rm -v -s -f $@
}

function exec_container () {
    local service="${1:?Require service as first parameter!}"
    local command="${2:-bash}"
    dc_in_env exec ${service} ${command}
}

function start_and_exec_container () {
    local service="${1:?Require service as first parameter!}"
    local command="${2:-bash}"
    start_services ${service}
    exec_container ${service} ${command}
}

function start_all_in_context () {
    _context="${1:?Require context as first parameter!}"
    log "INFO" "Beginning startup of ${_context}."
    dc_in_env up --no-recreate -d
    _context="all"
}

function start_infra_detached () {
    start_all_in_context "infra"
}

function start_deploy_detached () {
    start_all_in_context "deploy"
}

function start_deploy_attached () {
    log "INFO" "Beginning deployment of Emob."
    run_job topics-deploy
    run_job connectors-deploy
    run_job ksqlstatements-deploy
    run_job nodered-deploy
    log "INFO" "Completed deployment of Emob."
}

function start_testdata_detached () {
    start_all_in_context "testdata"
}

function start_testdata_attached () {
    log "INFO" "Beginning import of test data."
    run_job mqttmessages-send
    log "INFO" "Completed import of test data."
}

function start_all () {
    log "INFO" "Beginning startup of Emob infrastructure, deployment of Emob and import of test data."
    start_infra_detached
    start_deploy_attached
    start_testdata_attached
    log "INFO" "Completed startup of Emob infrastructure, deployment of Emob and import of test data."
}

function down_all () {
    log "INFO" "Shutting down all services."
    dc_in_env down -v --remove-orphans
}

function show_services () {
    _context="${1:-all}"
    dc_in_env config --services
    _context="all"
}

function show_logs () {
    _context="${1:-all}"
    shift
    dc_in_env logs -f $@
    _context="all"
}

function set_infra_mode () {
    local mode="${1:?"Require mode as first parameter! Valid modes are: 'single','ha','default'"}"

    if [ ! -z "$(dc_in_env ps -q)" ]; then
        log "WARNING" "Emob environment already started. You must shutdown environment first, in order to change the infra mode!"
        return
    fi

    if [ "${mode}" == "single" ]; then
        echo "${DC_INFRA_SINGLE}" > "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}"
    elif [ "${mode}" == "ha" ]; then
        echo "${DC_INFRA_HA}" > "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}"
    elif [ "${mode}" == "default" ]; then
        echo "${DC_INFRA_DEFAULT}" > "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}"
    else
        fail "'${mode}' is not a valid mode! Expected one of: single','ha','default'"
    fi

    log "INFO" "Switched to ${mode} mode."
}

function forward_kafka_cli () {
    dc_in_env run --rm workspace /workspace/emob-kafka.sh "$@"
}

## CLI Commands
_CMD=(
    'cmd=("mode" "Switch between single instance and ha mode. Requires that environment is down." "usage _CMD_MODE" "exec_cmd _CMD_MODE")'
    'cmd=("start" "Start Emob." "usage _CMD_START" "exec_cmd _CMD_START")'
    'cmd=("stop" "Stop a service." "usage _CMD_STOP" "exec_cmd _CMD_STOP")'
    'cmd=("down" "Shutdown Emob." "down_all" "exec_cmd _CMD")'
    'cmd=("logs" "Show logs of services." "usage _CMD_LOGS" "exec_cmd _CMD_LOGS")'
    'cmd=("ps" "Show running services." "dc_in_env ps" "dc_in_env ps")'
    'cmd=("cli" "Open a Emob Cli." "show_services cli" "start_and_exec_container")'
    'cmd=("dc" "Run any docker-compose command in environment" "dc_in_env" "dc_in_env")'
    'cmd=("kafka" "Emob Kafka cli in docker" "forward_kafka_cli" "forward_kafka_cli")'
)

_CMD_MODE=(
    'cmd=("single" "Switch to single instance mode." "set_infra_mode single" "exec_cmd _CMD_MODE")'
    'cmd=("ha" "Switch to ha mode." "set_infra_mode ha" "exec_cmd _CMD_MODE")'
)

_CMD_START=(
    'cmd=("all" "Startup of Emob infrastructure, deployment of Emob and import of test data." "time start_all" "exec_cmd _CMD_START")'
    'cmd=("infra" "Startup of Emob infrastructure (detached)." "time start_infra_detached" "exec_cmd _CMD_START")'
    'cmd=("deploy" "Deployment of Emob (attached)." "time start_deploy_attached" "exec_cmd _CMD_START")'
    'cmd=("testdata" "Import of test data (attached)." "time start_testdata_attached" "exec_cmd _CMD_START")'
    'cmd=("service" "Start specific services (detached)." "show_services" "time start_services")'
    'cmd=("job" "Start specific job (attached)." "show_services deploy && show_services testdata" "time run_job")'
)

_CMD_STOP=(
    'cmd=("service" "Stop specific services." "show_services" "time stop_services")'
)

_CMD_LOGS=(
    'cmd=("all" "Attach to logs of all services." "show_logs all" "show_logs all")'
    'cmd=("infra" "Attach to logs of infrastructure services." "show_logs infra" "show_logs infra")'
    'cmd=("deploy" "Attach to logs of deployment jobs." "show_logs deploy" "show_logs deploy")'
    'cmd=("testdata" "Attach to logs of test data import." "show_logs testdata" "show_logs testdata")'
    'cmd=("service" "Attach to logs of specific services." "show_services" "show_logs all")'
)

function usage () {
    local cmdsvar="${1:?Require available commands as first parameter!}"
    eval "_cmds=( \"\${${cmdsvar}[@]}\" )"
    echo "Commands:"
    for entry in "${_cmds[@]}"; do
        eval ${entry} 
        echo -e "  ${cmd[0]}\t\t${cmd[1]}"
    done
}

function exec_cmd () {
    local cmdsvar="${1:?Require available commands as first parameter!}"
    local action="${2:-""}"
    eval "_cmds=( \"\${${cmdsvar}[@]}\" )"
    for entry in "${_cmds[@]}"; do
        eval ${entry} 
        if [ "${cmd[0]}" == "${action}" ]; then
            shift 2
            if [ $# -eq 0 ]; then
                eval "${cmd[2]}"
            else
                eval "${cmd[3]} $@"
            fi 
            return
        fi
    done
    usage "$@"
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
   exec_cmd "_CMD" "$@"
fi