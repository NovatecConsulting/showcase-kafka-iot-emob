#!/usr/bin/env bash

docker exec -it postgres_db bash -c 'PGPASSWORD=test psql -h localhost -p 5432 -U postgres -c "CREATE database chargeIQ;"'

