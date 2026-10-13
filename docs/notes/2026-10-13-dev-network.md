# Dev network: VNet, subnets and NSGs

- Date: 2026-10-13

## What I built
A dev VNet (10.10.0.0/16) with three subnets: snet-appint for App Service outbound traffic, snet-pe for private endpoints and snet-agents for the private build agent. Each subnet has its own NSG. It is all Terraform, applied from a saved plan after review.

## Why it exists
The private App Service deployment needs a network to sit in. Every later layer (private endpoint, VNet integration, Key Vault, build agent) goes into one of these subnets, so the network has to exist first.

## How it works
The VNet is the private address space. Each subnet is a slice of it with one job. Each NSG is attached to its subnet and filters traffic by port, protocol and source, with priority numbers deciding which rule wins. snet-appint is delegated to Microsoft.Web/serverFarms so App Service can use it for outbound VNet integration. snet-pe holds the network interfaces of private endpoints, which is where an app's private inbound address will come from.

## What broke, and how I fixed it
Nothing broke on this piece. The plan showed 10 to add, 0 to change and 0 to destroy, and the apply matched it. One question I had: I first thought the PE subnet gave a private IP to the App Service itself. It does not. Only a private endpoint, created in a later layer, takes an address from it.

## Trade-offs
The NSGs have no custom rules yet, so only Azure's default rules apply. I will add explicit rules as each layer needs them. snet-appint is a /26 so the plan can scale out, which uses more addresses than a /28 would. Fine for dev; I would size it from expected scale in production. No hub-spoke or firewall yet; that comes later.

## Questions this answers in an interview
- What does an App Service need in a subnet for VNet integration, and why? (A dedicated subnet delegated to Microsoft.Web/serverFarms, used only for that.)
- Does VNet integration make the app private for inbound traffic? (No. It only controls outbound. Inbound privacy needs a private endpoint or access restrictions.)
- How does an NSG evaluate rules? (By priority, lowest number first, first match wins.)

## One-line pitch
I built the dev network in Terraform, with separate subnets for app outbound, private endpoints and build agents, each with its own NSG, so the rest of the private deployment has somewhere to sit.