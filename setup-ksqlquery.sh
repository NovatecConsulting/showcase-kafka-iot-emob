#!/usr/bin/env bash

curl -d @"./config/ksql-config/ksqlReadRawData.json" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -X POST "http://localhost:8088/ksql"  
curl -d @"./config/ksql-config/ksqlConvertRawChargeData.json" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -X POST "http://localhost:8088/ksql"  
curl -d @"./config/ksql-config/ksqlConvertRawBlinkData.json" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -X POST "http://localhost:8088/ksql"  
curl -d @"./config/ksql-config/ksqlChargeCompactTopic.json" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -X POST "http://localhost:8088/ksql"  
curl -d @"./config/ksql-config/ksqlChargeStatusLocation.json" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -X POST "http://localhost:8088/ksql"  

