#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
EMOB_DC_DIR=$(pwd)
if [ -e .env.override ]; then 
    set -a
    source .env.override
    set +a
fi
popd > /dev/null

DC_INFRA_CURRENT_FILE=".emob-dc-infra"
DC_INFRA_EXT_CURRENT_FILE=".emob-dc-infra-%s-extend"

DC_INFRA_DEFAULT="docker-compose.yaml"
DC_INFRA_HA="docker-compose.infra-ha.yaml"
DC_INFRA_SINGLE="docker-compose.infra-single.yaml"
DC_INFRA_SHOWCASE="docker-compose.infra-showcase.yaml"

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
    if [ -r "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}" ]; then
        cat "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}"
    else
        echo ${DC_INFRA_DEFAULT}
    fi
}

function determine_active_dc_infra_mode () {
    echo $(basename $(realpath $(determine_dc_infra_file))) | sed 's/^docker-compose\.infra-\([^\.]\+\)\..*$/\1/g'
}

function set_dc_infra_mode () {
    local mode="${1:?"Require mode as first parameter! Valid modes are: 'single','ha','showcase','default'"}"

    if [ ! -z "$(dc_in_env ps -q)" ]; then
        log "WARNING" "Emob environment already started. You must shutdown environment first, in order to change the infra mode!"
        return
    fi

    if [ "${mode}" == "single" ]; then
        echo "${DC_INFRA_SINGLE}" > "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}"
    elif [ "${mode}" == "ha" ]; then
        echo "${DC_INFRA_HA}" > "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}"
    elif [ "${mode}" == "showcase" ]; then
        echo "${DC_INFRA_SHOWCASE}" > "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}"
    elif [ "${mode}" == "default" ]; then
        echo "${DC_INFRA_DEFAULT}" > "${EMOB_DC_DIR}/${DC_INFRA_CURRENT_FILE}"
    else
        fail "'${mode}' is not a valid mode! Expected one of: single','ha','showcase','default'"
    fi

    log "INFO" "Switched to ${mode} mode."
}

function determine_available_infra_extensions () {
    for e in $(find . -regextype posix-extended -regex ".*docker-compose\.infra-$(determine_active_dc_infra_mode).extend-.*\.yaml$"); do
        echo $(basename "${e}") | sed "s/^docker-compose\.infra-$(determine_active_dc_infra_mode)\.extend-\([^\.]\+\)\..*$/\1/g"
    done
}

function determine_active_infra_extensions_file () {
    printf "${DC_INFRA_EXT_CURRENT_FILE}" "$(determine_active_dc_infra_mode)"
}

function determine_dc_infra_extension_files () {
    if [ -r "$(determine_active_infra_extensions_file)" ]; then
        cat $(determine_active_infra_extensions_file)
    fi
}

function determine_active_infra_extensions () {
    for e in $(determine_dc_infra_extension_files); do
        echo $(basename "${e}") | sed "s/^docker-compose\.infra-$(determine_active_dc_infra_mode)\.extend-\([^\.]\+\)\..*$/\1/g"
    done
}

function set_infra_extensions () {
    if [ ! -z "$(dc_in_env ps -q)" ]; then
        log "WARNING" "Emob environment already started. You must shutdown environment first, in order to change the infra extensions!"
        return
    fi
    if [ $# -ge 1 ]; then
        printf "docker-compose.infra-$(determine_active_dc_infra_mode).extend-%s.yaml " "$@" > "$(determine_active_infra_extensions_file)"
        log "INFO" "Activated extensions $* for $(determine_active_dc_infra_mode) mode."
    else
        printf "" > "$(determine_active_infra_extensions_file)"
        log "INFO" "Disabled all extensions for $(determine_active_dc_infra_mode) mode."
    fi
}

function with_dc_override_file () {
    local filename="${1:?Requires filename as first parameter!}"
    if [ "${filename}" = "docker-compose.yaml" ]; then
        filename="$(basename $(realpath "${filename}"))"
    fi
    local name="${filename%.*}"
    local extension="${filename##*.}"
    if [ -e "${name}.override.${extension}" ]; then
        printf "${filename} ${name}.override.${extension} "
    else
        printf "${filename} "
    fi
}

function with_dc_override_files () {
    for f in $@; do
        with_dc_override_file "${f}"
    done
}

function determine_dc_files () { 
    if [ "${_context}" == "infra" ]; then
        with_dc_override_files $(determine_dc_infra_file) $(determine_dc_infra_extension_files)
    elif [ "${_context}" == "deploy" ]; then
        with_dc_override_file "${DC_DEPLOY}"
    elif [ "${_context}" == "testdata" ]; then
        with_dc_override_file "${DC_TESTDATA}"
    elif [ "${_context}" == "cli" ]; then
        with_dc_override_file "${DC_CLI}"
    else
        with_dc_override_files $(determine_dc_infra_file) $(determine_dc_infra_extension_files) ${DC_DEPLOY} ${DC_TESTDATA} ${DC_CLI}
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

function forward_kafka_cli () {
    dc_in_env run --rm workspace /workspace/emob-kafka.sh "$@"
}

function determine_hostsfile () {
    local unameOut="$(uname -s)"
    local hostsfile
    case "${unameOut}" in
        Linux*)     hostsfile=/etc/hosts;;
        Darwin*)    hostsfile=/etc/hosts;;
        CYGWIN*)    hostsfile=/c/Windows/System32/drivers/etc/hosts;;
        MINGW*)     hostsfile=/c/Windows/System32/drivers/etc/hosts;;
        *)          hostsfile=""
    esac
    if [ -e "${hostsfile}" ]; then
        echo ${hostsfile}
    else
        echo ""
    fi
}

function enable_hostmanager () {
    local dockersocket=${1:-"/var/run/docker.sock"}
    local hostsfile=${2:-$(determine_hostsfile)}
    if [ ! -z ${hostsfile} ]; then
        if [ -z "$(docker ps -f name=docker-hostmanager -q)" ]; then
            docker run -d --name docker-hostmanager --restart=always -v ${dockersocket}:/var/run/docker.sock -v ${hostsfile}:/hosts iamluc/docker-hostmanager
            log "INFO" "Enabled Docker hostmanager. $(determine_hostsfile) file is automatically updated now."
        else
            log "INFO" "Docker hostmanager is already running."
        fi
    else
        log "ERROR" "Could not enable hostmanager, because hostsfile could not be located!"
    fi
}

function disable_hostmanager () {
    if [ ! -z "$(docker ps -f name=docker-hostmanager -q)" ]; then
        docker rm -f docker-hostmanager > /dev/null 2>&1 || true
        log "INFO" "Disabled Docker hostmanager. It may be necassary to manually clean up $(determine_hostsfile) file."
    fi
}

## CLI Commands
_CMD=(
    'cmd=("mode" "Switch between single instance and ha mode. Requires that environment is down." "usage _CMD_MODE" "exec_cmd _CMD_MODE")'
    'cmd=("showactivemode" "Show the active mode" "determine_active_dc_infra_mode" "exec_cmd _CMD")'
    'cmd=("modeex" "Enable or disable available extensions for the active mode" "usage _CMD_MODEEX" "exec_cmd _CMD_MODEEX")'
    'cmd=("start" "Start Emob." "usage _CMD_START" "exec_cmd _CMD_START")'
    'cmd=("stop" "Stop a service." "usage _CMD_STOP" "exec_cmd _CMD_STOP")'
    'cmd=("down" "Shutdown Emob." "down_all" "exec_cmd _CMD")'
    'cmd=("logs" "Show logs of services." "usage _CMD_LOGS" "exec_cmd _CMD_LOGS")'
    'cmd=("ps" "Show running services." "dc_in_env ps" "dc_in_env ps")'
    'cmd=("cli" "Open a Emob Cli." "show_services cli" "start_and_exec_container")'
    'cmd=("dc" "Run any docker-compose command in environment" "dc_in_env" "dc_in_env")'
    'cmd=("showdccontext" "Show active docker-compose files" "determine_dc_files" "exec_cmd _CMD")'
    'cmd=("hostmanager" "Manage Docker hostnames in your hosts file" "usage _CMD_HOSTMANAGER" "exec_cmd _CMD_HOSTMANAGER")'
    'cmd=("kafka" "Emob Kafka cli in docker" "forward_kafka_cli" "forward_kafka_cli")'
)

_CMD_MODE=(
    'cmd=("single" "Switch to single instance mode." "set_dc_infra_mode single" "exec_cmd _CMD_MODE")'
    'cmd=("ha" "Switch to ha mode." "set_dc_infra_mode ha" "exec_cmd _CMD_MODE")'
    'cmd=("showcase" "Switch to showcase instance mode." "set_dc_infra_mode showcase" "exec_cmd _CMD_MODE")'
)

_CMD_MODEEX=(
    'cmd=("setactive" "Sets the given set of extensions as active for the active infra mode." "determine_available_infra_extensions" "set_infra_extensions")'
    'cmd=("disable" "Disables all extensions for the active infra mode." "set_infra_extensions" "exec_cmd _CMD_MODEEX")'
    'cmd=("active" "Show active extensions for the active infra mode." "determine_active_infra_extensions" "exec_cmd _CMD_MODEEX")'
    'cmd=("available" "Show available extensions for the active infra mode." "determine_available_infra_extensions" "exec_cmd _CMD_MODEEX")'
)

_CMD_START=(
    'cmd=("all" "Startup of Emob infrastructure, deployment of Emob and import of test data." "time start_all" "exec_cmd _CMD_START")'
    'cmd=("infra" "Startup of Emob infrastructure (detached)." "time start_infra_detached" "exec_cmd _CMD_START")'
    'cmd=("deploy" "Deployment of Emob (attached)." "time start_deploy_attached" "exec_cmd _CMD_START")'
    'cmd=("testdata" "Import of test data (attached)." "time start_testdata_attached" "exec_cmd _CMD_START")'
    'cmd=("testdriver" "Start test driver to continuously simulate stations (detached)." "start_services driver" "exec_cmd _CMD_START")'
    'cmd=("service" "Start specific services (detached)." "show_services" "time start_services")'
    'cmd=("job" "Start specific job (attached)." "show_services deploy && show_services testdata" "time run_job")'
)

_CMD_STOP=(
    'cmd=("testdriver" "Stop test driver." "stop_services driver" "exec_cmd _CMD_STOP")'
    'cmd=("service" "Stop specific services." "show_services" "time stop_services")'
)

_CMD_LOGS=(
    'cmd=("all" "Attach to logs of all services." "show_logs all" "show_logs all")'
    'cmd=("infra" "Attach to logs of infrastructure services." "show_logs infra" "show_logs infra")'
    'cmd=("deploy" "Attach to logs of deployment jobs." "show_logs deploy" "show_logs deploy")'
    'cmd=("testdata" "Attach to logs of test data import." "show_logs testdata" "show_logs testdata")'
    'cmd=("testdriver" "Attach to logs of test driver." "dc_in_env logs -f driver" "dc_in_env -f driver")'
    'cmd=("service" "Attach to logs of specific services." "show_services" "show_logs all")'
)

_CMD_HOSTMANAGER=(
    'cmd=("enable" "Stop specific services." "enable_hostmanager" "enable_hostmanager")'
    'cmd=("disable" "Stop specific services." "disable_hostmanager" "exec_cmd _CMD_HOSTMANAGER")'
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
