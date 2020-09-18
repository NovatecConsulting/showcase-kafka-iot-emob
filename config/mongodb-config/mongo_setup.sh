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
    {CLIENT_ID:"CIQ100000001",lat:48.747,long:9.164},
    {CLIENT_ID:"CIQ100000002",lat:49.244,long:7.373},
    {CLIENT_ID:"CIQ100000003",lat:52.570,long:13.409},
    {CLIENT_ID:"CIQ100000004",lat:48.193,long:11.549},
    {CLIENT_ID:"CIQ100000005",lat:53.617,long:9.987},
    {CLIENT_ID:"CIQ100000006",lat:37.400,long:-3.609},
    {CLIENT_ID:"CIQ100000007",lat:48.684,long:9.168},
    {CLIENT_ID:"CIQ100000008",lat:50.118,long:8.647},
    {CLIENT_ID:"CIQ100000009",lat:51.317,long:12.344},
    {CLIENT_ID:"CIQ100000010",lat:52.425,long:9.517},
    {CLIENT_ID:"CIQ100000011",lat:53.088,long:9.799},
    {CLIENT_ID:"CIQ100000012",lat:47.677,long:9.174},
    {CLIENT_ID:"CIQ100000013",lat:48.682,long:9.161},
    {CLIENT_ID:"CIQ100000014",lat:49.038,long:8.418},
    {CLIENT_ID:"CIQ100000015",lat:51.057,long:13.764},
    {CLIENT_ID:"CIQ100000016",lat:49.456,long:11.104},
    {CLIENT_ID:"CIQ100000017",lat:51.009,long:6.954},
    {CLIENT_ID:"CIQ100000018",lat:48.520,long:9.060}
  ])
EOF
