# Private build agent: network egress and registration

## What I built
A self-hosted Azure DevOps agent on an Ubuntu virtual machine with no public IP.
Outbound access through a NAT gateway with a static public IP. Registration to an
agent pool in the Azure DevOps organisation using a dedicated service principal.

## Why it exists
Pipelines that deploy to a private App Service must run from inside the network.
The agent only makes outbound HTTPS calls to Azure DevOps and accepts no inbound
connections, so it needs egress and no ingress.

## How it works
The NAT gateway is associated with the agents subnet and translates outbound
traffic to one public address. The agent software is downloaded from Microsoft,
installed under /opt/azdo-agent and registered with the sp authentication type,
using VSTS_AGENT_INPUT_* environment variables. The secret is passed to the
machine as a protected parameter of a managed run command, so no SSH access or
public address is required.

## What broke, and how I fixed it
- The run command executes scripts with sh (dash), which rejected
  "set -o pipefail". The script now re-launches itself under bash.
- The run command service returned a transient InternalOperationError; a retry
  succeeded.
- The agent help text did not list the service principal option names. The
  environment variable convention was documented, and the registration succeeded
  on the first attempt.
- The dependency script printed errors for libicu78 and libicu76. These were
  benign: it tries newer versions and the installed libicu74 satisfied it.

## Trade-offs
A secret still exists briefly at registration. The service principal has the
smallest viable scope (one pool). A NAT gateway adds an hourly cost and is
removed with the workload each day. Daily rebuilds require daily registration.

## Questions this answers in an interview
- How does a private agent reach Azure DevOps without a public IP?
- How do you register an agent without leaving a secret behind?
- Why a service principal and not a personal access token?
- When would you use Managed DevOps Pools instead?

## One-line pitch
A private, outbound-only build agent registered with a single-purpose identity
whose secret exists only for the minutes it is needed.