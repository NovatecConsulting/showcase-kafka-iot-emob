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
    {CLIENT_ID:"CIQ000000001",x:48.747,y:9.164},
    {CLIENT_ID:"CIQ000000002",x:49.244,y:7.373},
    {CLIENT_ID:"CIQ000000003",x:52.570,y:13.409},
    {CLIENT_ID:"CIQ000000004",x:48.193,y:11.549},
    {CLIENT_ID:"CIQ000000005",x:53.617,y:9.987},
    {CLIENT_ID:"CIQ000000006",x:37.400,y:-3.609},
    {CLIENT_ID:"CIQ000000007",x:48.684,y:9.168},
    {CLIENT_ID:"CIQ000000008",x:50.118,y:8.647},
    {CLIENT_ID:"CIQ000000009",x:51.317,y:12.344},
    {CLIENT_ID:"CIQ000000010",x:52.425,y:9.517},
    {CLIENT_ID:"CIQ000000011",x:53.088,y:9.799},
    {CLIENT_ID:"CIQ000000012",x:47.677,y:9.174},
    {CLIENT_ID:"CIQ000000013",x:48.682,y:9.161},
    {CLIENT_ID:"CIQ000000014",x:49.038,y:8.418},
    {CLIENT_ID:"CIQ000000015",x:51.057,y:13.764},
    {CLIENT_ID:"CIQ000000016",x:49.456,y:11.104},
    {CLIENT_ID:"CIQ000000017",x:51.009,y:6.954},
    {CLIENT_ID:"CIQ000000018",x:48.520,y:9.060}
  ])
EOF
