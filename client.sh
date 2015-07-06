bind_ip=$(ip route | awk '/docker0/ { print $NF }' | tail -1)

docker run \
  --rm \
  --hostname=client.service.bltavares-dev.consul \
  --dns=$bind_ip \
  --dns-search=. \
  tutum/curl curl -s http://server:8000

docker run \
  --rm \
  --hostname=client.service.bltavares-dev.consul \
  --dns=$bind_ip \
  --dns-search=. \
  tutum/dnsutils dig server.service.bltavares-dev.consul

docker run \
  --rm \
  --hostname=client.service.bltavares-dev.consul \
  --dns=$bind_ip \
  --dns-search=. \
  tutum/dnsutils dig server.service.bltavares-staging.consul
