curl -d @"connect-mqtt-source.json" -H "Content-Type: application/json" -X POST http://localhost:8083/connectors 
curl -d @"connect-mongodb-sink.json" -H "Content-Type: application/json" -X POST http://localhost:8083/connectors  
