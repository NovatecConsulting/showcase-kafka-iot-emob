#!/usr/bin/env bash

curl -d @"./config/ksql-config/ksqlConvertRawData.json" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -X POST "http://localhost:8088/ksql" 
curl -d @"./config/ksql-config/ksqlCompactTopic.json" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -X POST "http://localhost:8088/ksql"  

