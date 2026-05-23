# Project Aurora — Claude Code Instructions

## What this project is

A 4-week Azure portfolio build for Nordlux Outfitters (fictional Stockholm outdoor-apparel retailer).
Demonstrates Cloud Engineer + Solution Architect + Cloud Administrator skills on a single Azure Free Account.
Hard budget ceiling: USD 180 / ~1,890 SEK. Alert at USD 90.

## Repo structure

```
project-aurora/
├── CLAUDE.md                    ← you are here
├── infra/
│   ├── governance/              ← Week 1 (deployed)
│   ├── network/                 ← Week 2 (deployed)
│   ├── identity/                ← Week 3 in progress
│   │   ├── main.bicep
│   │   └── modules/
│   │       ├── managed-identity.bicep
│   │       └── role-assignment.bicep
│   └── workload/                ← Week 3 remaining (not yet built)
├── .github/workflows/
│   ├── deploy-dev.yml
│   └── deploy-prod.yml
├── docs/
│   └── adr/                     ← ADRs 0001–0008 exist
└── teardown.ps1
```

## Hard rules — never break these

### Naming (from 02_naming_and_tagging.md)
Pattern: `nx-<env>-<workload>-<region>-<resource>-<instance>`
- org prefix: always `nx`
- env: `dev`, `prod`, `shared`
- workload: `web`, `api`, `data`, `ai`, `obs`, `net`, `sec`, `gov`
- region: `swc` (swedencentral) or `weu` (westeurope) — NO other regions
- instance: 3-digit zero-padded, e.g. `001`
- all lowercase, hyphens only (no underscores)
- Storage accounts and Container Registry: no hyphens, ≤24 chars → pattern `nx<env><workload><region>st<instance>`

Resource group exception — no region or instance: `nx-<env>-<workload>-rg`

### Mandatory tags — every resource, no exceptions
```
Environment: dev | prod | shared
Workload:    web | api | data | ai | obs | net | sec | gov
CostCenter:  aurora-portfolio
Owner:       <owner email param>
```

### Regions
Default: `swedencentral`. Fallback: `westeurope`. Never any other region.

### IaC language
Bicep only. No Terraform, no ARM JSON. Every Bicep file:
- Starts with the standard file header (see Bicep standards below)
- Declares `targetScope` explicitly
- Uses only stable (non-preview) API versions
- Has `@description` on every parameter
- Computes resource names in variables, never hardcoded
- Sends diagnostic settings to `nx-shared-obs-swc-log-001` in `nx-shared-obs-rg`
- Outputs `id`, `name`, `principalId` (where applicable) — never secrets or connection strings

### Bicep file header (mandatory on every file)
```bicep
// ============================================================================
// Module: <name>
// Purpose: <one sentence>
// Owner: <owner>
// Last reviewed: <YYYY-MM-DD>
// Cost impact: <free | ~$X/mo | per-use>
// ============================================================================
targetScope = '<scope>'
```

### Standard parameter set (every module)
```bicep
@description('Environment short name.')
@allowed(['dev', 'prod', 'shared'])
param environmentName string

@description('Workload short name.')
@allowed(['web', 'api', 'data', 'ai', 'obs', 'net', 'sec', 'gov'])
param workload string

@description('Azure region.')
@allowed(['swedencentral', 'westeurope'])
param location string = 'swedencentral'

@description('Three-digit instance counter, zero-padded.')
@minLength(3)
@maxLength(3)
param instance string = '001'

param tags object
```

### Cost rules (from 03_cost_guardrails.md)
NEVER deploy:
- Azure Bastion (~$140/mo) → use JIT VM access instead
- Azure Firewall (~$900/mo) → use NSGs + Front Door WAF
- Application Gateway v2 (~$180/mo) → use Front Door Standard
- Azure DDoS Protection Standard (~$2,944/mo)
- Any Premium SKU of anything

Deploy briefly only (include teardown timing):
- Azure Front Door Standard + WAF (~$35/mo) → 7 days max, Week 3 only

Always free — deploy freely:
- VNets, NSGs, Private DNS Zones, Managed Identities, Azure Policy
- App Service Linux B1 (750 hrs/mo free, 12 mo)
- Azure SQL Serverless (100k vCore-seconds free, 12 mo)
- Cosmos DB free tier (1000 RU/s + 25 GB — one account per sub)
- Container Apps Consumption (180k vCPU-sec free/mo)
- Azure AI Search Free SKU (50 MB + 3 indexes)
- Log Analytics + App Insights (5 GB/mo)

### Security rules (from 04_security_baseline.md)
- No secrets in source code, Bicep outputs, or parameter files committed to git
- All secrets go to Key Vault, accessed via managed identity
- No subscription-scoped Owner assignments to MIs — use Contributor + User Access Administrator at RG scope
- All NSGs: default-deny inbound + outbound, then narrow allow rules
- Prod App Service: Front Door is sole ingress (AzureFrontDoor.Backend service tag + X-Azure-FDID header check)
- HTTPS only, TLS 1.2+ on all internet-facing resources
- Every resource sends diagnostic logs to central Log Analytics workspace

### PowerShell for admin tasks
Use PowerShell (not Azure CLI) for ad-hoc admin scripts.
`Get-AzConsumptionUsageDetail` does NOT work on Azure Free Account — use `Invoke-AzRestMethod` against `Microsoft.CostManagement/query` (api-version 2023-11-01) instead.

## Azure subscription context
- Subscription ID: b6a09e3b-710e-4828-9bb5-6b4c482b39ac
- Billing currency: SEK (~10.5 SEK/USD)
- Budget thresholds: $90 alert (~945 SEK), $180 hard ceiling (~1,890 SEK)
- Free Account, ~28 days remaining

## What is already deployed (do not redeploy)

### Week 1 — Governance ✅
- Cost Management budget ($180, alerts at 50%/80%/100%)
- Action group: `nx-shared-gov-swc-ag-001`
- 5 Azure Policy assignments (allowed locations, 4 required tags)
- Log Analytics: `nx-shared-obs-swc-log-001` in `nx-shared-obs-rg`
- Entra: break-glass account, Cloud Admin, App Developer, sg-cloud-admins, sg-app-developers
- Security Defaults enabled

### Week 2 — Network ✅
Resource groups: `nx-shared-net-rg`, `nx-dev-net-rg`, `nx-prod-net-rg`

VNets:
- Hub: `nx-shared-net-swc-vnet-001` 10.10.0.0/16
  - snet-shared 10.10.3.0/24, snet-mgmt 10.10.4.0/24
- Dev: `nx-dev-net-swc-vnet-001` 10.20.0.0/16
  - snet-app 10.20.1.0/24 (delegated Microsoft.Web/serverFarms)
  - snet-data 10.20.2.0/24, snet-test 10.20.3.0/24
- Prod: `nx-prod-net-swc-vnet-001` 10.30.0.0/16
  - snet-app 10.30.1.0/24 (delegated Microsoft.Web/serverFarms)
  - snet-data 10.30.2.0/24
  - snet-pe 10.30.3.0/24 (Private Endpoints)
  - snet-aca 10.30.4.0/23 (delegated Microsoft.App/environments)

NSGs: 9 NSGs (one per subnet), baseline default-deny rules
Peerings: Hub↔Dev bidirectional, Hub↔Prod bidirectional (no spoke-to-spoke)
Private DNS zones (in hub RG, linked to all 3 VNets):
- privatelink.database.windows.net
- privatelink.azurewebsites.net
- privatelink.vaultcore.azure.net
- privatelink.documents.azure.com
- privatelink.openai.azure.com
- privatelink.search.windows.net

## What to build next (Week 3 — in progress)

### Currently building: OIDC Pipeline (identity/)
Files exist in infra/identity/ — see Prompt 2 for deploy instructions.

### Remaining Week 3 stack (build in this order)
1. Key Vault (prod with Private Endpoint in snet-pe, dev with IP firewall)
2. Storage Account (prod with PE, dev with IP firewall)
3. Azure SQL Serverless + Cosmos DB free tier
4. App Service Linux B1 + Container Apps (Consumption)
5. Front Door Standard + WAF (7-day window only — include teardown reminder)

## ADRs written (do not contradict these decisions)
- 0001: Defer RG-location policy enforcement
- 0002: Conditional Access via Security Defaults (not P1 CA)
- 0003: GitHub over Azure DevOps
- 0004: NSG names include subnet name instead of instance counter
- 0005: Explicit dependsOn for NSG→VNet attachment
- 0006: Cost telemetry via Cost Management query API (not Consumption cmdlets)
- 0007: Budget thresholds mapped USD→SEK
- 0008: Per-environment user-assigned MIs for CI/CD (not shared, not service principal)

## When I ask you to build something

1. Check naming against the pattern above before writing a single line
2. Check cost against the three tiers above — flag before proceeding if deploy-briefly or never-deploy
3. Check security rules — no secrets in outputs, no subscription-scope Owner
4. Write what-if command before deploy command, always
5. Add the file header to every Bicep file
6. Add the four mandatory tags to every resource
7. Wire diagnostic settings to `nx-shared-obs-swc-log-001`
