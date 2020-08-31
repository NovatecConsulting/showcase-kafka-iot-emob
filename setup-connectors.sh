#!/usr/bin/env bash

#Create 4 connectors
curl -d @"./config/connectors-config/connect-mqtt-source.json" -H "Content-Type: application/json" -X POST http://localhost:8083/connectors
curl -d @"./config/connectors-config/connect-mongodb-sink.json" -H "Content-Type: application/json" -X POST http://localhost:8083/connectors  
curl -d @"./config/connectors-config/connect-mongodb-source.json" -H "Content-Type: application/json" -X POST http://localhost:8083/connectors
curl -d @"./config/connectors-config/connect-jdbc-sink.json" -H "Content-Type: application/json" -X POST http://localhost:8083/connectors    

