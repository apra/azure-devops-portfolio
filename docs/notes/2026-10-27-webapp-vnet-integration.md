# Regional VNet integration for the web app

## What I built
VNet integration attaching the App Service web app to a dedicated delegated
subnet (snet-appint, 10.10.1.0/26).

## Why it exists
The web app needs outbound access to private resources, starting with Key Vault
through a private endpoint. Inbound access is already handled by the private
endpoint.

## How it works
The subnet is delegated to Microsoft.Web/serverFarms, which gives the App Service
platform exclusive use of it. Setting virtual_network_subnet_id on the web app
routes its outbound traffic to private address ranges through that subnet.
vnet_route_all_enabled is left at its default (false), so internet-bound traffic
is unchanged.

## What broke, and how I fixed it
The first local plan showed a virtual machine replacement unrelated to this change
(see the cloud-init note). The web app change itself was a single in-place update.

## Trade-offs
Routing all traffic through the VNet would need an egress path on the subnet and
belongs with the Firewall and route table work. The integration needs Basic tier
or above.

## Questions this answers in an interview
- What is the difference between a private endpoint and VNet integration?
- Why does the integration subnet need delegation?

## One-line pitch
Private endpoint for inbound, VNet integration for outbound: the two halves of a
private App Service.