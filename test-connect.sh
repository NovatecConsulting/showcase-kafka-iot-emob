#!/usr/bin/env sh

# Test data is managed in ./testdata directory.
# Mqtt messages can be defined in *.csv files in directory ./testdata/mqtt.
# Messages which were defined in this script have been migrated to ./testdata/mqtt/mqttmessages.csv.
# The script /testdata/mqtt/mqttmessages-send.sh automatically sends 
# all messages defined in *.csv files in alphabeticall order to the Mqtt broker.
# This script, or in more detail, the ./emob-dc.sh script executes 
# the send script in a Docker container and handles retries.

echo "Deprecated: Use ./emob-dc.sh start testdata"
exec $(dirname $0)/emob-dc.sh start testdata
