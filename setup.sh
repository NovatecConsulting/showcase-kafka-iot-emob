#!/usr/bin/env sh

# Atomatically deploys topics, connectors and ksqlDB statements.

echo "Deprecated: Use ./emob-dc.sh start deploy"
exec $(dirname $0)/emob-dc.sh start deploy