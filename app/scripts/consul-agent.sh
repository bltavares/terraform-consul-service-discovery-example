#!/bin/bash
set -e

docker pull progrium/consul

CONSUL_ADDRESS=$(cat /tmp/app-consul-addr | tr -d '\n')
IDENTIFIER=$(cat /tmp/app-server-identifier | tr -d '\n')
IP=$(ip route | awk '/eth1/ { print $NF }' | tail -1)

sudo mkdir -p /mnt/consul

docker run -d \
  --name consul-agent \
  -h $HOSTNAME \
  -v /mnt/consul:/data \
  -p 8300:8300 \
  -p 8301:8301 \
  -p 8301:8301/udp \
  -p 8302:8302 \
  -p 8302:8302/udp \
  -p 8400:8400 \
  -p 8500:8500 \
  -p 53:53/udp \
  -l "SERVICE_NAME=consul" \
  progrium/consul -advertise $IP -join $CONSUL_ADDRESS -dc $IDENTIFIER
