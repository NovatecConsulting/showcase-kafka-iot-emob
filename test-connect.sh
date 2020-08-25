#!/usr/bin/env bash

docker run -it --rm --name mqtt-publisher --network showcase_emob efrecon/mqtt-client pub -h hivemq -t "CIQ000000017/out/charge" -m "ev"
docker run -it --rm --name mqtt-publisher --network showcase_emob efrecon/mqtt-client pub -h hivemq -t "CIQ000000017/out/charge" -m "ready"
docker run -it --rm --name mqtt-publisher --network showcase_emob efrecon/mqtt-client pub -h hivemq -t "CIQ000000017/out/charge" -m "charging"
docker run -it --rm --name mqtt-publisher --network showcase_emob efrecon/mqtt-client pub -h hivemq -t "CIQ000000017/out/charge" -m "charged; amount 20 of 20"
docker run -it --rm --name mqtt-publisher --network showcase_emob efrecon/mqtt-client pub -h hivemq -t "CIQ000000017/out/charge" -m "ev"

