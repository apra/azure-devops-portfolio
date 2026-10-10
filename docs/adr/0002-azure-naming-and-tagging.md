# ADR 0002: Azure naming and tagging convention

- Status: Accepted
- Date: 2026-10-10

## Context

Azure resources are created by Terraform across several environments. Many
resource names cannot be changed after creation, and names and tags are how
cost, ownership and environment are identified later. I needed one pattern
before creating any resources.

## Decision

Names follow the Cloud Adoption Framework pattern:

    <type>-<workload>-<env>-<region>-<instance>

For example, rg-portfolio-dev-uks-001.

| Resource | Prefix |
|---|---|
| Resource group | rg |
| Virtual network | vnet |
| Subnet | snet |
| Network security group | nsg |
| Key Vault | kv |
| App Service plan | asp |
| App Service | app |
| Private endpoint | pep |
| Log Analytics workspace | log |
| Storage account | st (no hyphens; see below) |

Storage account names must be 3-24 lowercase letters and numbers and be
globally unique, so they use the form st<workload><purpose><region> plus a
short random suffix, for example stportfoliotfstuks4821.

Region: UK South (abbreviated uks) for all resources.

Every resource that supports tags carries:

- project: the workload name
- environment: dev, test or prod
- owner: the person accountable
- managed-by: always terraform

## Alternatives considered

- No convention, or provider-generated names: fastest, but cost reports and
  ownership become guesswork, and renaming means recreating resources.
- A longer pattern including team and cost centre: closer to a large
  organisation, but adds length for no benefit with one owner and one
  subscription. It can be extended later.

## Consequences

- Positive: any resource can be identified from its name and tags alone,
  and Azure Policy can later enforce the required tags.
- Negative: the storage account exception means one resource breaks the
  pattern, and a random suffix is needed for uniqueness.
- Negative: tags must be applied on every resource. The azurerm provider has
  no default_tags feature, so a shared local.tags map is passed to each
  resource.