#!/usr/bin/env bash

#Create necessary topics
create_topic "wallbox_source"
create_topic "wallbox_charge"
#Create 2 connectors
curl -d @"./config/connectors-config/connect-mqtt-source.json" -H "Content-Type: application/json" -X POST http://localhost:8083/connectors 
curl -d @"./config/connectors-config/connect-mongodb-sink.json" -H "Content-Type: application/json" -X POST http://localhost:8083/connectors  
