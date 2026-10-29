# Key Vault private endpoint and private DNS

## What I built
A private endpoint for the foundation Key Vault in snet-pe, a private DNS zone
privatelink.vaultcore.azure.net and a link from the zone to the foundation
virtual network, in the workload stack.

## Why it exists
The vault denies all public network access. The private endpoint is its only
network path, used by the private build agent and by the web app through VNet
integration.

## How it works
The endpoint places a network interface with a private address in snet-pe for the
vault sub-resource. A DNS zone group registers the address in the private zone.
Inside the linked virtual network, the vault hostname resolves through a
privatelink alias to the private address; outside, it resolves publicly where the
vault firewall refuses access. The vault is in the persistent stack and the
endpoint in the workload stack, so the endpoint is created and destroyed daily
while the vault remains.

## What broke, and how I fixed it
Nothing failed. The vault name is a hash of the subscription ID, so the workload
stack recomputes the same expression to find the vault without cross-stack state.

## Trade-offs
The duplicated name expression must stay in step between the two stacks; a
mismatch fails loudly at plan time. Disabling the vault's public network access
entirely is a separate foundation change.

## Questions this answers in an interview
- How does a private endpoint to Key Vault work, and what does the DNS zone do?
- How do you reach a network-restricted vault from an agent and an application?

## One-line pitch
A vault with no public path, reachable only through a private endpoint and a
private DNS zone, verified from inside the network.