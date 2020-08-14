#!/usr/bin/env bash

docker run -it --rm --name mqtt-publisher --network showcase_emob efrecon/mqtt-client pub -h hivemq -t "CIQ000000017/out/charge" -m "20"
