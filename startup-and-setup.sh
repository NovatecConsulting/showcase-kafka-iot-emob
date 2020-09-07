#!/usr/bin/env sh

# Automatically starts the emob infrastructre services, 
# deploys the application (topc creation, connectors and ksqlDB statement deployment) 
# and imports test data.

# By default the single instance set up is executed. 
# With "./emob-dc.sh mode ha" yo can switch to a HA setup.

echo "Deprecated: Use ./emob-dc.sh start all"
exec $(dirname $0)/emob-dc.sh start all