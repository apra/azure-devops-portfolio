# ADR 0004: Azure DevOps organisation and project

- Status: Accepted
- Date: 2026-10-26
- Issue: #54

## Context

The delivery scope includes Azure DevOps Pipelines, a central template library
consumed through `extends`, environments with approvals, service connections and
private build agents. Each of these depends on an Azure DevOps organisation and
project. The existing GitHub Actions pipeline is retained as a working
comparison.

Azure DevOps organisations cannot be created through Terraform or the Azure
Resource Manager. Creation is a portal operation.

## Decision

1. Create one Azure DevOps organisation, `<ORGANISATION NAME>`, signed in with a
   dedicated Entra administrator account in the tenant, so that the organisation
   is backed by the Entra directory and not by a personal Microsoft account.
2. Host the organisation in the United Kingdom region.
3. Create one project, `portfolio`, with private visibility.
4. Confirm the following settings after creation and record the observed state:
   - Microsoft Entra connection: `<OBSERVED: tenant shown / not shown>`
   - Allow public projects policy: `<OBSERVED: off / not displayed>`
   - Project visibility: no visibility control is displayed in Project settings;
     an unauthenticated request to the project URL in a private browser session
     `<OBSERVED: redirected to sign-in>`.
   - Membership of Project Collection Administrators: `<OBSERVED>`

## Manual exception

Organisation and project creation is performed manually in the portal because no
infrastructure-as-code interface exists for it. Resources created inside the
organisation (pipelines, environments, service connections, agent pools) will be
created through source-controlled definitions where the platform supports it.

## Consequences

- Authentication and conditional access for Azure DevOps are inherited from
  Entra.
- Azure DevOps has separate billing, agent pools and permissions from the Azure
  subscription. Self-hosted pipelines use the free self-hosted parallel job;
  confirm the current allowance under Organization settings, Parallel jobs.
- The administrator account retains broad rights. Reducing them is tracked in the
  hardening backlog.

## Follow-ups

- Select the agent registration method that avoids a long-lived stored secret and
  record it in the agent installation Issue.
- Create a service connection to Azure using workload identity federation in
  Phase B.
- Restrict project permissions and enable audit logging when additional users are
  added.