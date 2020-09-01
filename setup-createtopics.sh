#!/usr/bin/env bash

source .env

create_topic(){
    docker run --rm --net=showcase_emob confluentinc/cp-server:${VERSION_CONFLUENT} kafka-topics --create --bootstrap-server kafka:9092 --partitions 6 --replication-factor 3 --topic $1
}

create_compacted_topic(){
    docker run --rm --net=showcase_emob confluentinc/cp-server:${VERSION_CONFLUENT} kafka-topics --create --bootstrap-server kafka:9092 --partitions 6 --replication-factor 3 --config cleanup.policy=compact --topic $1
}

#Create necessary topics
create_topic "wallbox_source"
create_topic "wallbox_charge"
create_topic "wallbox_blink"
create_compacted_topic "wallbox_chargestatus"
create_compacted_topic "wallbox_location"
create_compacted_topic "wallbox_location_chargestatus"

