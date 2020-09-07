#!/usr/bin/env sh

# Connectors are managed in ./config/connectors-config directory.
# The script ./config/connectors-config/connectors-deploy.sh automatically 
# deploys all connectors defined in *.json files in alphabeticall order to Kafka Connect.
# This script, or in more detail, the ./emob-dc.sh script executes 
# the deploy script in a Docker container and handles retries.

# Note: The script connectors-deploy.sh ensures, that the default replication factor of the 
#   Kafka brokers is set to confluent.topic.replication.factor attributes in connector configs.

echo "Deprecated: Use ./emob-dc.sh start job connectors-deploy"
exec $(dirname $0)/emob-dc.sh start job connectors-deploy