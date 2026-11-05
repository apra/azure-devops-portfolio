# End-to-end private deployment through a self-hosted agent

## What I built
A complete deployment path with no public network exposure. A self-hosted agent
inside the virtual network builds the application, and a deployment stage
publishes it to an App Service whose public access is disabled. The application
reads a secret through a Key Vault reference over private endpoints. The run on
2 November confirmed the chain from the agent, using the response
`{"message":"hello-from-key-vault"}`.

## Why it exists
A Microsoft-hosted agent cannot reach an App Service deployment endpoint that is
reachable only through a private endpoint. The self-hosted agent is the part that
makes a private-only application deployable by a pipeline, and the run demonstrates
that the networking, identity and secret handling work together.

## How it works
- The workload stack is applied manually from main and creates the agent VM, NAT
  gateway, App Service, private endpoints and private DNS zones.
- The agent's first-boot configuration installs the agent software. Registration
  uses a service principal secret that lives for one day and is deleted
  immediately after registration (ADR 0005).
- The pipeline definition in Azure DevOps runs the Build stage, which archives the
  application, and the Deploy stage, which uses the deployment identity from the
  federated service connection to publish to the web app.
- A final step requests the application from the agent and checks for the
  expected response. Private DNS resolves the web app's name to its private
  address from inside the network.

## What broke, and how I fixed it
1. **Pool not visible to the project.** The pipeline was rejected because the
   project could not see the agent pool. The pool belongs to the organisation and
   had to be linked to the project, without granting access to all pipelines.
2. **Missing archive utility.** The archive task needs `zip`, which the base image
   lacks. It was installed manually for the session and added to the first-boot
   configuration (#96).
3. **First-run authorisations.** The pipeline had to be authorised once for the
   service connection, the environment and the pool.
4. **Check ran before the application was ready.** The verification step received
   the platform's default page, because the platform build completes after the
   deployment task returns. `curl --retry` does not retry a successful response
   with the wrong content. The step now polls for the expected content with a
   bounded number of attempts (#94).
5. **Unplanned apply run.** Merging a change to the workload stack started the
   apply workflow automatically. It remained pending and was cancelled before it
   made any change, so the running agent was not replaced. The apply trigger
   rules are documented in the runbook as a result.

## Trade-offs
- A self-hosted agent adds a VM to patch and pay for. Managed DevOps Pools would
  remove that operational work and still run inside the network.
- Package installation after upload makes deployments slower but keeps the
  artifact independent of the build host.
- Polling makes the check tolerant of slow starts, with a hard limit so that a
  real failure still fails the run.

## Questions this answers in an interview
- How do you deploy to an App Service that has no public access?
- Why can a Microsoft-hosted agent not do it, and what are the alternatives?
- What does an agent pool need before a project's pipelines can use it?
- How do you make a post-deployment check reliable?
- How do you keep a registration secret short-lived and out of the repository?

## One-line pitch
A pipeline running inside the network deployed a private-only application that
reads its secret from Key Vault, with no public exposure and no stored secret.
