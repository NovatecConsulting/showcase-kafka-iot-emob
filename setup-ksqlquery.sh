#!/usr/bin/env sh

# Ksql statements are managed in ./config/ksql-config directory.
# The script ./config/ksql-config/ksqlstatements-deploy.sh automatically 
# deploys all ksql statements defined in *.json files in alphabeticall order to ksqlDB.
# This script, or in more detail, the ./emob-dc.sh script executes 
# the deploy script in a Docker container and handles retries.

echo "Deprecated: Use ./emob-dc.sh start job ksqlstatements-deploy"
exec $(dirname $0)/emob-dc.sh start job ksqlstatements-deploy