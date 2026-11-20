# Disabling public network access on the Key Vault

## What I built
The Key Vault in the foundation stack has public network access disabled, so the
private endpoint is the only path to the vault. The existing network rules,
which deny by default, are retained as a second layer.

## Why it exists
The vault already denied public traffic through its network rules, but its
public endpoint was still enabled and still accepted traffic from trusted
services and any allowed address. All legitimate access is through the private
endpoint, so the public endpoint served no purpose and remained an attack
surface. Removing it makes the private endpoint the single route in.

## How it works
- A vault has two layers of network control. The firewall rules decide which
  addresses and services may reach the public endpoint. The public network
  access setting decides whether that endpoint exists for client traffic at all.
- With the setting disabled, a request from the internet is refused regardless
  of the firewall rules. Requests from inside the virtual network resolve the
  vault's name to the private endpoint address through the private DNS zone.
- Authorisation is unchanged. It remains Azure RBAC, and the web app's managed
  identity holds Key Vault Secrets User on the vault. Network access and
  authorisation are separate controls, and both must allow a request.

## What broke, and how I fixed it
1. **Loss of the earlier seeding method.** On 29 October the test secret was
   written through a temporary firewall rule for one public address. That
   method no longer works, because the endpoint is closed. This is recorded in
   ADR 0003. Secret values are now written from inside the network, from the
   private build agent, or by a controlled pipeline.
2. **Workload plan listed as additions.** The pull request plan for the
   workload stack listed all of its resources as additions, because the
   workload is destroyed between sessions and the plan compares against empty
   state. This was expected and informational. It did lead to a reminder that
   merging a change under the workload stack path starts an apply workflow,
   which must be cancelled when no session is running.
3. **Pending verification.** The setting was confirmed as disabled on the vault
   after the gated apply. That the web app's Key Vault reference still resolves
   is verified in the next session's deployment run, and is not yet confirmed.

## Trade-offs
- Writing a secret now needs a path into the network. The private agent
  provides one, which makes the agent a dependency for secret management. A
  jump host or Azure Bastion would be alternatives, at additional cost.
- The retained network rules are redundant while the setting is disabled. They
  are kept so that re-enabling public access, for a diagnosis, does not open the
  vault to all addresses.
- A disabled public endpoint also blocks the portal's data-plane views from the
  administrator's own machine. Management operations still work.
- I have not verified whether the trusted-services bypass has any effect when
  public access is disabled. The bypass is not relied on in this design.

## Questions this answers in an interview
- What is the difference between Key Vault firewall rules and disabling public
  network access?
- How does a private endpoint work, and why does it need a private DNS zone?
- How do you manage secrets in a vault that has no public access?
- How do network controls and RBAC combine?
- What do you lose when you close the public endpoint, and how do you cope?

## One-line pitch
The vault is reachable only through its private endpoint, with authorisation by
RBAC, and secrets are written from inside the network.
