#!/usr/bin/env sh
SCRIPT_DIR=$(dirname $0)

MQTT_BROKER_HOST=${MQTT_BROKER_HOST:-localhost}
MQTT_BROKER_MQTTPORT=${MQTT_BROKER_MQTTPORT:-1883}

function log () {
    local level="${1:?Requires log level as first parameter!}"
    local msg="${2:?Requires message as second parameter!}"
    echo -e "$(date -u)|${level}|${msg}"
}

function wait_until_available () {
    until mosquitto_pub --quiet -h ${MQTT_BROKER_HOST} -p ${MQTT_BROKER_MQTTPORT} -t "health" -m "test"; do echo -n "."; sleep 2; done
}

function send_mqttmessage () {
    local topic="${1:?Requires topic as first parameter!}"
    local msg="${2:?Requires messages as first parameter!}"
    local client="$(echo "${topic}" | cut -d/ -f1)"
    mosquitto_pub -h ${MQTT_BROKER_HOST} -p ${MQTT_BROKER_MQTTPORT} -i "${client}" -t "${topic}" -m "${msg}" -r 2>&1
}

function send_mqttmessages_in_file () {
    local file=${1:?Requires filename as first parameter!}
    local filebasename="$(basename "${file}")"
    local lineno=0
    while read -r line; do
        let "lineno++"
        local topic=$(echo ${line} | cut -d, -f1)
        local msg=$(echo ${line} | cut -d, -f2)
        local response="$(send_mqttmessage "${topic}" "${msg}" && echo OK)"
        if [ "${response}" == "OK" ]; then
            log "INFO" "Successfully sent Mqtt message ${filebasename}:${lineno} to broker: \"${line}\""
        else
            log "ERROR" "Could not sent Mqtt message ${filebasename}:${lineno} to Broker: ${response}"
            return 1
        fi
    done < ${file}
}

function send_mqttmessages_in_dir () {
    local configdir=${1:?Requires dir as first parameter!}
    local return_code=0;
    for file in $(find "${configdir}" -name "*.csv" | sort); do
        send_mqttmessages_in_file "${file}"
        if [ $? -ne 0 ]; then
            return_code=1
        fi
    done
    return ${return_code}
}

function main () {
    wait_until_available
    local target="${1:-${SCRIPT_DIR}}"
    if [ -d "${target}" ]; then
        send_mqttmessages_in_dir "${target}"
    else
        send_mqttmessages_in_file "${target}"
    fi
}

main "$@"