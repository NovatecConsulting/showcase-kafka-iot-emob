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
    {CLIENT_ID:"CIQ100000001",latitude:48.747,longitude:9.164},
    {CLIENT_ID:"CIQ100000002",latitude:49.244,longitude:7.373},
    {CLIENT_ID:"CIQ100000003",latitude:52.570,longitude:13.409},
    {CLIENT_ID:"CIQ100000004",latitude:48.193,longitude:11.549},
    {CLIENT_ID:"CIQ100000005",latitude:53.617,longitude:9.987},
    {CLIENT_ID:"CIQ100000006",latitude:37.400,longitude:-3.609},
    {CLIENT_ID:"CIQ100000007",latitude:48.684,longitude:9.168},
    {CLIENT_ID:"CIQ100000008",latitude:50.118,longitude:8.647},
    {CLIENT_ID:"CIQ100000009",latitude:51.317,longitude:12.344},
    {CLIENT_ID:"CIQ100000010",latitude:52.425,longitude:9.517},
    {CLIENT_ID:"CIQ100000011",latitude:53.088,longitude:9.799},
    {CLIENT_ID:"CIQ100000012",latitude:47.677,longitude:9.174},
    {CLIENT_ID:"CIQ100000013",latitude:48.682,longitude:9.161},
    {CLIENT_ID:"CIQ100000014",latitude:49.038,longitude:8.418},
    {CLIENT_ID:"CIQ100000015",latitude:51.057,longitude:13.764},
    {CLIENT_ID:"CIQ100000016",latitude:49.456,longitude:11.104},
    {CLIENT_ID:"CIQ100000017",latitude:51.009,longitude:6.954},
    {CLIENT_ID:"CIQ100000018",latitude:48.520,longitude:9.060}
  ])
EOF
