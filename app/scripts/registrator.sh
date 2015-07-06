#!/bin/bash
set -e

docker pull gliderlabs/registrator:master
IP=$(ip route | awk '/eth0/ { print $NF }' | tail -1)

docker run -d \
    -v /var/run/docker.sock:/tmp/docker.sock \
    --add-host=dockerhost:$(ip route | awk '/docker0/ { print $NF }') \
    -h $HOSTNAME gliderlabs/registrator:master -ip $IP consul://dockerhost:8500
