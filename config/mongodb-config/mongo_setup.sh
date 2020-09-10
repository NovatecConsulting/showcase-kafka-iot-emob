#!/usr/bin/env bash

echo SETUP.sh time now: `date +"%T" `
echo "Configure mongoDB in replica set mode"
# it ins necessary to advertise ip, in order to enable external access to mnongo
mongo --host mongo:27017 <<EOF
  var cfg = {
    "_id": "rs0",
    "version": 1,
    "members": [
      {
        "_id": 0,
        "host": "$(dig +short mongo | tail -n1):27017",
        "priority": 2
      }
    ]
  };
  rs.initiate(cfg, { force: true });
  rs.reconfig(cfg, { force: true });
  db.getMongo().setReadPref('nearest');
EOF

echo "Insert test data to mongoDB"
mongo --host mongodb://mongo:27017/?replicaSet=rs0 <<EOF
  use mongoDB;
  db.createCollection("ChargingStations");
  db.createCollection("StationLocations");
  db.StationLocations.insertMany([
    {CLIENT_ID:"CIQ000000017",x:25.1,y:25.2},
    {CLIENT_ID:"CIQ000000001",x:35.1,y:35.2},
    {CLIENT_ID:"CIQ000000012",x:45.1,y:45.2}
  ])
EOF