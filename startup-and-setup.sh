#!/usr/bin/env bash
set -e
date +"%T"
docker-compose up -d
echo "This could take several minutes:"
while [[ $(docker inspect -f {{.State.Health.Status}} connect) != *healthy* ]]; do
    echo -ne "\r\033[0KWaiting for connect service to be healthy";
    sleep 1
    echo -n "."
    sleep 1
    echo -n "."
    sleep 1
    echo -n "."
done

echo "connect service is healthy"

echo "Setting up connectors & ksql"
source ./setup.sh

echo "test connection"
source ./test-connect.sh
date +"%T"