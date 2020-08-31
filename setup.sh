#!/usr/bin/env bash

# Create necessary topics
source ./setup-createtopics.sh

# setup Kafka connectors
source ./setup-connectors.sh

# setup KSQL streaming processor
source ./setup-ksqlquery.sh

# setup PostgreSQL Database
source ./setup-postgres.sh "test" "CREATE database chargeIQ;" "exit"
