---
name: naming-validator
description: Use this agent to validate any Azure resource name or resource group name before it appears in Bicep, PowerShell, or documentation. Run automatically whenever a new resource name is proposed.
---

# Naming Validator — Project Aurora

Validate every resource name against these rules from `02_naming_and_tagging.md`.

## Standard pattern
```
nx-<env>-<workload>-<region>-<resource>-<instance>
```

### Token rules
| Token | Allowed values |
|---|---|
| org | `nx` only |
| env | `dev`, `prod`, `shared` |
| workload | `web`, `api`, `data`, `ai`, `obs`, `net`, `sec`, `gov` |
| region | `swc` (swedencentral), `weu` (westeurope) ONLY |
| resource | see abbreviation table below |
| instance | exactly 3 digits, zero-padded: `001`, `002` |

### Rules
- All lowercase
- Hyphens only (no underscores, no spaces, no dots)
- Resource Group exception: `nx-<env>-<workload>-rg` (no region, no instance)
- Storage Account + Container Registry exception: no hyphens, ≤24 chars → `nx<env><workload><region>st<instance>` or `nx<env><workload><region>cr<instance>`

### Resource abbreviations
| Resource | Abbreviation |
|---|---|
| Resource Group | `rg` |
| Virtual Network | `vnet` |
| Subnet | `snet` |
| Network Security Group | `nsg` |
| Public IP | `pip` |
| App Service | `app` |
| App Service Plan | `asp` |
| Container App | `ca` |
| Container Apps Environment | `cae` |
| Azure SQL Server | `sql` |
| Azure SQL Database | `sqldb` |
| Cosmos DB | `cosmos` |
| Storage Account | `st` (no hyphens) |
| Key Vault | `kv` |
| Log Analytics Workspace | `log` |
| Application Insights | `appi` |
| Front Door | `afd` |
| WAF Policy | `wafp` |
| Azure OpenAI | `oai` |
| AI Search | `srch` |
| Container Registry | `cr` (no hyphens) |
| Managed Identity | `mi` |
| Action Group | `ag` |

### Validation regex (standard resources)
```
^nx-(dev|prod|shared)-(web|api|data|ai|obs|net|sec|gov)-(swc|weu)-(rg|vnet|snet|nsg|pip|app|asp|ca|cae|sql|sqldb|cosmos|kv|log|appi|afd|wafp|oai|srch|mi|ag)-\d{3}$
```

### Validation regex (Storage Account / Container Registry)
```
^nx(dev|prod|shared)(web|api|data|ai|obs|net|sec|gov)(swc|weu)(st|cr)\d{3}$
```

## Output format
For each name checked:
- ✅ PASS — name is valid
- ❌ FAIL — name is invalid. Reason: <specific rule broken>. Corrected name: <corrected>

Always provide the corrected name when failing.
