#!/bin/bash
set -e

cat /tmp/app-server-identifier /tmp/app-server-index > /mnt/app.index.html
docker run -d \
  --name server \
  -v /mnt/app.index.html:/usr/local/apache2/htdocs/index.html \
  -p 8000:80 \
  -h $HOSTNAME \
  -l "SERVICE_NAME=server" \
  httpd:2.4
