// ============================================================================
// Module: data/main
// Purpose: Deploys dev and prod Storage Accounts; prod gets a Private Endpoint.
//          Also creates the privatelink.blob.core.windows.net DNS zone (missing
//          from Week 2) and links it to all 3 VNets.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-24
// Cost impact: free (Storage LRS free tier) + ~$7/mo (1 prod PE)
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

@description('Home IP address allowed through the dev Storage Account firewall. Do not commit real IPs.')
param homeIpAddress string

@description('Object ID of the Entra user or group to set as SQL Active Directory admin.')
param azureAdAdminObjectId string

// ---------------------------------------------------------------------------
// Derived variables
// ---------------------------------------------------------------------------
var subId = subscription().subscriptionId

var logAnalyticsId = '/subscriptions/${subId}/resourceGroups/nx-shared-obs-rg/providers/Microsoft.OperationalInsights/workspaces/nx-shared-obs-swc-log-001'
var snetPeId       = '/subscriptions/${subId}/resourceGroups/nx-prod-net-rg/providers/Microsoft.Network/virtualNetworks/nx-prod-net-swc-vnet-001/subnets/snet-pe'

// VNet IDs needed to link the new blob DNS zone to all 3 VNets (same set as Week 2 zones)
var hubVnetId  = '/subscriptions/${subId}/resourceGroups/nx-shared-net-rg/providers/Microsoft.Network/virtualNetworks/nx-shared-net-swc-vnet-001'
var devVnetId  = '/subscriptions/${subId}/resourceGroups/nx-dev-net-rg/providers/Microsoft.Network/virtualNetworks/nx-dev-net-swc-vnet-001'
var prodVnetId = '/subscriptions/${subId}/resourceGroups/nx-prod-net-rg/providers/Microsoft.Network/virtualNetworks/nx-prod-net-swc-vnet-001'

var sharedTags = {
  CostCenter: 'aurora-portfolio'
  Owner: ownerEmail
}

#disable-next-line no-hardcoded-env-urls
var sqlDnsZoneId = '/subscriptions/${subId}/resourceGroups/nx-shared-net-rg/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net'

// ---------------------------------------------------------------------------
// Existing resource groups
// ---------------------------------------------------------------------------
resource hubNetRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: 'nx-shared-net-rg'
}

resource devDataRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: 'nx-dev-data-rg'
}

resource prodDataRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: 'nx-prod-data-rg'
}

// ---------------------------------------------------------------------------
// New Private DNS zone for blob storage — missing from Week 2 deployment
// Placed in hub RG, linked to all 3 VNets to match existing zone pattern
// ---------------------------------------------------------------------------
// #disable-next-line no-hardcoded-env-urls — this IS the DNS zone name, not a URL
module blobDnsZone '../network/modules/private-dns.bicep' = {
  name: 'deploy-dns-privatelink-blob-core-windows-net'
  scope: hubNetRg
  params: {
    #disable-next-line no-hardcoded-env-urls
    zoneName: 'privatelink.blob.core.windows.net'
    vnetIds: [hubVnetId, devVnetId, prodVnetId]
    tags: { Environment: 'shared', Workload: 'net', CostCenter: 'aurora-portfolio', Owner: ownerEmail }
  }
}

// ---------------------------------------------------------------------------
// Dev Storage Account — public access, home IP firewall only
// ---------------------------------------------------------------------------
module devSa 'modules/storage.bicep' = {
  name: 'deploy-dev-sa'
  scope: devDataRg
  params: {
    environmentName: 'dev'
    workload: 'data'
    location: location
    instance: instance
    publicNetworkAccess: 'Enabled'
    allowedIpAddress: homeIpAddress
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'dev', Workload: 'data' })
  }
}

// ---------------------------------------------------------------------------
// Prod Storage Account — no public access, Private Endpoint only
// ---------------------------------------------------------------------------
module prodSa 'modules/storage.bicep' = {
  name: 'deploy-prod-sa'
  scope: prodDataRg
  params: {
    environmentName: 'prod'
    workload: 'data'
    location: location
    instance: instance
    publicNetworkAccess: 'Disabled'
    allowedIpAddress: ''
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'prod', Workload: 'data' })
  }
}

// ---------------------------------------------------------------------------
// Private Endpoint for prod Storage Account — blob subresource, snet-pe
// Uses blobDnsZone.outputs.id to let Bicep sequence PE after zone creation
// ---------------------------------------------------------------------------
module prodSaPe 'modules/private-endpoint.bicep' = {
  name: 'deploy-prod-sa-pe'
  scope: prodDataRg
  params: {
    environmentName: 'prod'
    workload: 'data'
    location: location
    instance: instance
    serviceId: prodSa.outputs.id
    serviceGroupId: 'blob'
    subnetId: snetPeId
    privateDnsZoneId: blobDnsZone.outputs.id
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'prod', Workload: 'data' })
  }
}

// ---------------------------------------------------------------------------
// Dev SQL Server + database — public access, home IP + Azure services allowed
// ---------------------------------------------------------------------------
module devSql 'modules/sql-server.bicep' = {
  name: 'deploy-dev-sql'
  scope: devDataRg
  params: {
    environmentName: 'dev'
    workload: 'data'
    location: location
    instance: instance
    publicNetworkAccess: 'Enabled'
    allowedIpAddress: homeIpAddress
    azureAdAdminObjectId: azureAdAdminObjectId
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'dev', Workload: 'data' })
  }
}

// ---------------------------------------------------------------------------
// Prod SQL Server + database — no public access; PE wired below
// ---------------------------------------------------------------------------
module prodSql 'modules/sql-server.bicep' = {
  name: 'deploy-prod-sql'
  scope: prodDataRg
  params: {
    environmentName: 'prod'
    workload: 'data'
    location: location
    instance: instance
    publicNetworkAccess: 'Disabled'
    allowedIpAddress: ''
    azureAdAdminObjectId: azureAdAdminObjectId
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'prod', Workload: 'data' })
  }
}

// ---------------------------------------------------------------------------
// Private Endpoint for prod SQL — sqlServer subresource, snet-pe
// Uses privatelink.database.windows.net deployed in Week 2 (nx-shared-net-rg)
// instance '002' avoids name collision with storage PE '001'
// ---------------------------------------------------------------------------
module prodSqlPe 'modules/private-endpoint.bicep' = {
  name: 'deploy-prod-sql-pe'
  scope: prodDataRg
  params: {
    environmentName: 'prod'
    workload: 'data'
    location: location
    instance: '002'
    serviceId: prodSql.outputs.serverId
    serviceGroupId: 'sqlServer'
    subnetId: snetPeId
    privateDnsZoneId: sqlDnsZoneId
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'prod', Workload: 'data' })
  }
}

// ---------------------------------------------------------------------------
// Cosmos DB free-tier account — shared dev/prod, deployed in nx-dev-data-rg
// One free-tier account per subscription; single region to stay in free tier
// ---------------------------------------------------------------------------
module cosmos 'modules/cosmos.bicep' = {
  name: 'deploy-cosmos'
  scope: devDataRg
  params: {
    environmentName: 'shared'
    workload: 'data'
    location: location
    instance: instance
    logAnalyticsWorkspaceId: logAnalyticsId
    tags: union(sharedTags, { Environment: 'shared', Workload: 'data' })
  }
}

// ---------------------------------------------------------------------------
// Outputs — endpoints only; no connection strings or keys
// ---------------------------------------------------------------------------
output devSaId              string = devSa.outputs.id
output devSaName            string = devSa.outputs.name
output devSaBlobEndpoint    string = devSa.outputs.primaryBlobEndpoint
output prodSaId             string = prodSa.outputs.id
output prodSaName           string = prodSa.outputs.name
output prodSaBlobEndpoint   string = prodSa.outputs.primaryBlobEndpoint
output prodPeId             string = prodSaPe.outputs.id
output blobDnsZoneId        string = blobDnsZone.outputs.id
output devSqlServerId       string = devSql.outputs.serverId
output devSqlServerName     string = devSql.outputs.serverName
output devSqlServerFqdn     string = devSql.outputs.serverFqdn
output prodSqlServerId      string = prodSql.outputs.serverId
output prodSqlServerName    string = prodSql.outputs.serverName
output prodSqlServerFqdn    string = prodSql.outputs.serverFqdn
output prodSqlPeId          string = prodSqlPe.outputs.id
output cosmosId             string = cosmos.outputs.id
output cosmosName           string = cosmos.outputs.name
output cosmosEndpoint       string = cosmos.outputs.endpoint
