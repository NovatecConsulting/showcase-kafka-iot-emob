#!/usr/bin/env bash

curl -d @"./config/ksql-config/ksqlquery.json" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -X POST "http://localhost:8088/ksql" 



