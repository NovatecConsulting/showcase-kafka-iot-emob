#!/usr/bin/env bash
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(pwd)
popd > /dev/null

KAFKA_BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:19092}"
SCHEMAREGISTRY_URL="${SCHEMAREGISTRY_URL:-http://localhost:8081}"
KAFKA_TOPICS_CMD="${KAFKA_TOPICS_CMD:-$(which kafka-topics || which kafka-topics.sh || echo "")}"
KAFKA_CONSOLE_CONSUMER_CMD="${KAFKA_CONSOLE_CONSUMER_CMD:-$(which kafka-console-consumer || which kafka-console-consumer.sh || echo "")}"
KAFKA_AVRO_CONSOLE_CONSUMER_CMD="${KAFKA_AVRO_CONSOLE_CONSUMER_CMD:-$(which kafka-avro-console-consumer || which kafka-avro-console-consumer.sh || echo "")}"


function show_topics () {
    ${KAFKA_TOPICS_CMD} --bootstrap-server ${KAFKA_BOOTSTRAP_SERVER} --list --topic "^[^_].*"
}

function consume_topic_binary () {
    local topic="${1:?Requires topic as first parameter!}"
    shift
    ${KAFKA_CONSOLE_CONSUMER_CMD} --bootstrap-server ${KAFKA_BOOTSTRAP_SERVER} \
        --property print.key=true \
        --topic "${topic}" $@
}

function consume_topic_avro () {
    local topic="${1:?Requires topic as first parameter!}"
    shift
    ${KAFKA_AVRO_CONSOLE_CONSUMER_CMD} --bootstrap-server ${KAFKA_BOOTSTRAP_SERVER} \
        --property schema.registry.url=${SCHEMAREGISTRY_URL} \
        --key-deserializer=org.apache.kafka.common.serialization.StringDeserializer \
        --property print.key=true \
        --topic "${topic}" $@
}

function check_is_topic_in_sr () {
    local topic="${1:?Requires topic as first parameter!}"
    local http_code=$(timeout 10 curl -s -w "%{http_code}" -o /dev/null "${SCHEMAREGISTRY_URL}/subjects/${topic}-value/versions")
    if [[ "${http_code}" =~ ^2.* ]]; then
        return 0
    else
        return 1
    fi
}

function consume_topic_dependant () {
    local topic="${1:?Requires topic as first parameter!}"
    shift
    check_is_topic_in_sr "${topic}"
    if [ $? -eq 0 ]; then
       consume_topic_avro "${topic}" $@
    else
       consume_topic_binary "${topic}" $@
    fi 
}

## CLI Commands
_CMD=(
    'cmd=("topics" "List topics" "show_topics" "exec_cmd _CMD")'
    'cmd=("consume" "Start Emob." "show_topics" "consume_topic_dependant")'
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