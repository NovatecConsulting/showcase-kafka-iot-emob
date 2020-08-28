#!/usr/bin/env bash

# Create necessary topics
source ./setup-createtopics.sh

# setup Kafka connectors
source ./setup-connectors.sh

# setup KSQL streaming processor
source ./setup-ksqlquery.sh
