#!/bin/bash
set -e

# Read from the file we created
SERVER_IDENTIFIER=$(cat /tmp/consul-server-identifier | tr -d '\n')

cd /tmp
wget https://dl.bintray.com/mitchellh/consul/0.5.2_web_ui.zip -O web-ui.zip
unzip web-ui.zip >/dev/null
sudo rm -f /mnt/web
sudo mv dist /mnt/web

# Write the flags to a temporary file
cat >/tmp/consul_flags << EOF
export CONSUL_FLAGS="-data-dir=/mnt/consul -dc ${SERVER_IDENTIFIER} -ui-dir /mnt/web -client 0.0.0.0"
export BIND="0.0.0.0"
EOF

# Write it to the full service file
sudo mv /tmp/consul_flags /etc/service/consul
chmod 0644 /etc/service/consul
