## Consul and Terraform for service discovery

This is an extension experiment of
[dns-lookup](https://github.com/bltavares/docker-dns-lookup-example)
exploration.
It sets up a Consul server and applications on a cluster of servers,
closer to what a deployment of a system would look like.

The setup makes use of Terraform to provision all the servers. Each
environment (eg: staging, production) would have its state stored on
different files, and have different variables.

## Setup

The project is split on two different modules. One will setup the
Consul cluster and the other will setup the application nodes. They
are located on different folders, and could be developed separatelly.

To satisfy terraform dependency loader, execute `terraform get` to get
those folders linked.

It is only configured to use OpenStack providers.

The Consul node was addapted from the
[Consul OpenStack](https://github.com/hashicorp/consul/tree/master/terraform/openstack)
scripts.

To start the setup, let's create a variable with a identifier. It's
just a human readable identifier for the environments. It will be used
on the commands to lookup the variable files and the state files.

```bash
identifier=production
```

We can start checking what would be the changes required on our
providers to setup the cluster. You will need to add all the required
variables on the `$identifier.tfvars` file.

```bash
terraform plan -var-file=$identifier.tfvars -state=$identifier.tfstate -module-depth=1  -input=false
```

It should include all the required credentials to create the OpenStack
servers as well as replicate the identifier on the file.


## The identifier

The identifier is important to separate each environment. It could be
anything, like `dallas-staging`, `production`,
`branch-1023-test`. This should separate each environment while still
using the same shared configuration. Using this helps to include the
code on a continous integration server and have changes on the
infrastructure follow the same flow as developing features.

## Applying the changes

Now you can apply the changes on the infrastructure. The `terraform
plan` command has an option to write the plan on a file so there are
no differences from the time you saw the plan and the time you applied
the changes. I will be not dealing with that and I will just apply the changes.

```bash
terraform apply -var-file=$idenfier.tfvars -state=$idenfier.tfstate -input=false
```

It should be spinning up servers and keys and you can go grab a
coffee. There could be some [issues](#Issues), so adjust accordingly
to your setup.

The deployment scripts were supposed to start the cluster and let all
the nodes aware of each other, but there are [issues](#Issues). So we
will need to join all of them together ourselves.

## Manual steps

We will spin up 3 Consul servers as well as 1 Consul agent with the Web Interface.
You will need to ssh into each of the nodes and run:

```
consul join $internal_ip
```

where `$internal_ip` is one of the ips that it is assigned to one of the servers.
You can use different ip addresses, as they will share the information
and let everybody aware of all the servers. After all is joined, head
to the "consul_ui" ip on port 8500 and see how your cluster is
running. You can include Key/Values on the interface, as well as check
nodes and service health status.

The web module is confireud to connect to the consul web ui node, and
it should not need any setup. When the cluster get's connected it
should be running fine. If it is not, you can mark the web nodes as
"tainted" and apply changes again. This will recreate the web nodes,
but not the cluster.

```bash
terraform taint -state=$idenfier.tfstate -module=app openstack_compute_instance_v2.app_node.0
terraform taint -state=$idenfier.tfstate -module=app openstack_compute_instance_v2.app_node.1
terraform apply -var-file=$idenfier.tfvars -state=$idenfier.tfstate -input=false
```

# Multiple datacenters/environments

If we create another identifier and fill in the variables, we should
be able to create a deployment on another environment, like a staging
environment, using the same code.

Consul was created with that in mind. Each cluster is participant of
its dc ring, but could also participate of a global wan ring. Consul
does not setup the tunneling needed to make cross-datacenter
communication, but on this test case I ran two clusters, staging and
production, on the same region and virtual network to keep things simple.

Change the identifier to store the state of the other region and
change the variables on the new file (specially the identifier
variable to help you identify things from the ui).
```bash
identifier=staging
terraform apply -var-file=$idenfier.tfvars -state=$idenfier.tfstate -input=false
```

You will need to repeat the manual steps for the second cluster as
well because of the issues.

After each cluster is communicating with itself, we can now make the
nodes join the wan pool. Each of the nodes that would have access to
the ips on the other cluster would need to be ssh'd and execute:

```bash
consul join -wan $other_node_ip
```

You can pass the ip on another node on the same dc, but at least one
wan join must be between the different dcs.
You can see the members of the same dc cluster and the -wan servers.

```bash
consul members
consul members -wan
```

After a bunch of nodes are displaying on the server's -wan ring, you
should see that information being replicated on the Consul Web UI (top
right). Now, a client that is on the production cluster can query the
service of the staging cluster if specified.

A note that the tunneling between the service and the client across dc
is still needed to be managed separatelly. The test used the same
network, so all nodes could talk to each other.

## The web node services

The web node has Docker installed to make it easier to run and install
different applications.  On that node, the Consul agent is running as
a Docker container, and exposing the ports to the host, so other
docker containers can interact with the host over the docker bridge
ip.

Also, to facilitate the service registration on the consul cluster, we
are running a `gliderlabs/registrator:master` container. It listens on
the Docker socket for container startup events, then inspects the
exposed ports and register the service and port pair on the cluster.
This would help when you have a Docker container running many
different services.

It connects to the Consul Agent running as a Docker container,
throught the `docker0` ports that are forwarded. The agent itself is
the one that contacts the cluster. So for each Docker host, we would
have a pair of Consul Agent and registrator running, to provide
service registry and health check for the other service containers.

The other container is a HTTP serving a file that is specific to each
host, so we can see the service locator working together with the load
balancer, using the DNS interface provided by Consul.

## Clients to access the server application

As the web node has docker, we can make use of that to run the client
as well. The script uses a small container that has curl installed, to
demonstrate the DNS resolution as described on the
[dns-lookup](https://github.com/bltavares/docker-dns-lookup-example) repo.

As there is a Consul Agent exposed to the host ports, we can use the
`docker0` ip from inside the container to make DNS lookups.

ssh into any of the two web nodes and start the client container. You
should see it alternating between the node responses.

```bash
bind_ip=$(ip route | awk '/docker0/ { print $NF }' | tail -1)

docker run \
  --rm \
  --hostname=client.service.production.consul \
  --dns=$bind_ip \
  --dns-search=. \
  tutum/curl curl -s http://server:8000

```

If you've setup the multi datacenter clusters, from one dc web node
you should be able to query the other dc service as well.
```bash
production-web-node $ bind_ip=$(ip route | awk '/docker0/ { print $NF }' | tail -1)

# from the production web node, create a staging client
production-web-node $ docker run \
  --rm \
  --hostname=client.service.staging.consul \
  --dns=$bind_ip \
  --dns-search=. \
  tutum/curl curl -s http://server:8000

```

To explore more the DNS resolution answers, you can start a container
with dns utils installed and configured to use consul as the lookup.

```bash
bind_ip=$(ip route | awk '/docker0/ { print $NF }' | tail -1)
docker run \
  --rm \
  --hostname=client.service.production.consul \
  --dns=$bind_ip \
  --dns-search=. \
  -ti \
  tutum/dnsutils bash
```

## Issues

- When specifing another network, the ip assignment is delayed and the private ip is not provided as a value for the rest of the bootstrap provisioning. That is why you need to manually connect the cluster.
- The OpenStack provider on Terraform is not dealing well with the Rackspace network creation, so the id of a pre-configured network is provided. https://github.com/hashicorp/terraform/issues/1560
