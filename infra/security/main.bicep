// ============================================================================
// Module: security/main
// Purpose: Deploys dev Key Vault, prod Key Vault, and prod Key Vault PE.
//          Front Door + WAF skipped — blocked on Free Trial (see ADR 0009/0010).
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-25
// Cost impact: ~$0.03/10k ops (Key Vault) + ~$7/mo (1 prod PE)
// ============================================================================

targetScope = 'subscription'

@description('Azure region for all resources.')
@allowed(['swedencentral', 'westeurope'])
param location string = 'swedencentral'

@description('Three-digit instance counter, zero-padded.')
@minLength(3)
@maxLength(3)
param instance string = '001'

@description('Your email address — used in Owner tag.')
param ownerEmail string = 'you@example.com'

@description('Home IP address allowed through the dev Key Vault firewall. Required — do not commit real IPs.')
param homeIpAddress string

// ---------------------------------------------------------------------------
// Derived variables
// ---------------------------------------------------------------------------
var subId = subscription().subscriptionId

var logAnalyticsId = '/subscriptions/${subId}/resourceGroups/nx-shared-obs-rg/providers/Microsoft.OperationalInsights/workspaces/nx-shared-obs-swc-log-001'
var snetPeId       = '/subscriptions/${subId}/resourceGroups/nx-prod-net-rg/providers/Microsoft.Network/virtualNetworks/nx-prod-net-swc-vnet-001/subnets/snet-pe'
var kvDnsZoneId    = '/subscriptions/${subId}/resourceGroups/nx-shared-net-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'

var sharedTags = {
  CostCenter: 'aurora-portfolio'
  Owner:      ownerEmail
}

// ---------------------------------------------------------------------------
// Existing resource groups
// ---------------------------------------------------------------------------
resource devSecRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: 'nx-dev-sec-rg'
}

resource prodSecRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: 'nx-prod-sec-rg'
}

// ---------------------------------------------------------------------------
// Dev Key Vault — public access, home IP firewall only
// ---------------------------------------------------------------------------
module devKv 'modules/keyvault.bicep' = {
  name:  'deploy-dev-kv'
  scope: devSecRg
  params: {
    environmentName:         'dev'
    workload:                'sec'
    location:                location
    instance:                instance
    publicNetworkAccess:     'Enabled'
    allowedIpAddress:        homeIpAddress
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'dev', Workload: 'sec' })
  }
}

// ---------------------------------------------------------------------------
// Prod Key Vault — no public access, Private Endpoint only
// ---------------------------------------------------------------------------
module prodKv 'modules/keyvault.bicep' = {
  name:  'deploy-prod-kv'
  scope: prodSecRg
  params: {
    environmentName:         'prod'
    workload:                'sec'
    location:                location
    instance:                instance
    publicNetworkAccess:     'Disabled'
    allowedIpAddress:        ''
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'prod', Workload: 'sec' })
  }
}

// ---------------------------------------------------------------------------
// Private Endpoint for prod Key Vault — placed in snet-pe (nx-prod-net-rg)
// ---------------------------------------------------------------------------
module prodKvPe 'modules/private-endpoint.bicep' = {
  name:  'deploy-prod-kv-pe'
  scope: prodSecRg
  params: {
    environmentName:         'prod'
    workload:                'sec'
    location:                location
    instance:                instance
    serviceId:               prodKv.outputs.id
    serviceGroupId:          'vault'
    subnetId:                snetPeId
    privateDnsZoneId:        kvDnsZoneId
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'prod', Workload: 'sec' })
  }
}

// ---------------------------------------------------------------------------
// Outputs — IDs and hostnames only; no secrets or connection strings
// ---------------------------------------------------------------------------
output devKvId   string = devKv.outputs.id
output devKvName string = devKv.outputs.name
output prodKvId  string = prodKv.outputs.id
output prodKvName string = prodKv.outputs.name
output prodKvUri string = prodKv.outputs.uri
output prodPeId  string = prodKvPe.outputs.id
