# App Service private endpoint, private DNS and disabled public access

## What I built
A private endpoint for the web app in snet-pe, a private DNS zone
privatelink.azurewebsites.net linked to the foundation virtual network, and the
public network access setting of the web app turned off.

## Why it exists
To make the web app reachable only from inside the network, so that only the
private build agent can deploy to it.

## How it works
The private endpoint places a network interface with a private address
(10.10.2.4) in snet-pe. The DNS zone group registers the address in the private
zone. From inside the linked virtual network the public hostname resolves
through a privatelink alias to the private address. Outside the network the same
name resolves to the public address, where requests are now refused.

## What broke, and how I fixed it
Nothing failed. The endpoint's customDnsConfigs field was empty in the CLI
because DNS is managed through a zone group; the address was confirmed from the
DNS record set instead.

## Trade-offs
A private endpoint does not disable the public endpoint. They are separate
steps, taken in two changes so that name resolution could be verified first.
Deployments from outside the network no longer work, which is intended.

## Questions this answers in an interview
- Why does a private endpoint need a private DNS zone?
- Does a private endpoint make the service private by itself?
- How do you verify a private path before removing the public one?

## One-line pitch
The same hostname resolves to a private address inside the network and is
refused outside it.