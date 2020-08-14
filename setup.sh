#!/usr/bin/env bash

source .env

create_topic(){
     docker run --rm --net=showcase_emob confluentinc/cp-server:${VERSION_CONFLUENT} kafka-topics --create --bootstrap-server kafka:9092 --partitions 6 --replication-factor 3 --topic $1
}

# setup Kafka connectors
source ./setup-connectors.sh

# setup KSQL streaming processor
source ./setup-ksqlquery.sh
