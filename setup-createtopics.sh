#!/usr/bin/env sh

# Topics are managed in ./config/topics-config directory.
# The script ./config/topics-config/topics-deploy.sh automatically 
# deploys all topics defined in *.json files in alphabeticall order to Kafka.
# This script, or in more detail, the ./emob-dc.sh script executes 
# the deploy script in a Docker container and handles retries.

echo "Deprecated: Use ./emob-dc.sh start job topics-deploy"
exec $(dirname $0)/emob-dc.sh start job topics-deploy