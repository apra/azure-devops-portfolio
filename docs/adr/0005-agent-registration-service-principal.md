# ADR 0005: Self-hosted agent registration with a short-lived service principal secret

- Status: Accepted
- Date: 2026-10-26
- Issue: #56

## Context

The private build agent runs on a virtual machine without a public IP address in
snet-agents. It must register with the Azure DevOps organisation, which requires
a credential at registration time. Microsoft documents service principal
registration for self-hosted agents (agent 3.227.1 and later) and states that the
client secret is used only during registration. No documented registration method
for self-hosted agents uses a managed identity without a secret.

## Decision

1. Register the agent with a dedicated service principal
   (sp-azdo-agent-registration) that holds no Azure role assignments, Basic
   access in the organisation, and the Administrator role on the agent pool
   pool-private-uks only.
2. Create a client secret with a two-day expiry immediately before registration.
3. Deliver the secret to the virtual machine as a protected parameter of an
   Azure managed run command. The agent reads it from the
   VSTS_AGENT_INPUT_CLIENTSECRET environment variable, so it never appears on a
   command line or in a repository.
4. Delete the secret in Entra ID and remove the run command object after
   registration succeeds.
5. Run the agent as the unprivileged user azureagent under a systemd service.

## Manual exception

Registration is performed manually. The service principal, its secret and the
pool role assignment are created outside Terraform. The agent software is
installed by a one-off run command.

## Consequences

- The virtual machine is recreated daily. Each recreation requires a new secret
  and a repeat of the installation and registration steps.
- The service principal remains in Entra ID and in the pool, with no usable
  credential between registrations.
- The secret exists for the duration of registration only.

## Follow-ups

- Bootstrap the agent software through cloud-init in Terraform (no secret
  involved).
- Store the registration secret in Key Vault and let the virtual machine retrieve
  it through its managed identity at registration time.
- Compare with Managed DevOps Pools, which do not require a registration secret.