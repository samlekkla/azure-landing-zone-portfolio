// ============================================================================
// Module: sql-server
// Purpose: Deploys an Azure SQL Server (Entra-only auth) and a Serverless
//          General Purpose database (autoPause 60 min, 0.5–1 vCore).
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-24
// Cost impact: free (100k vCore-seconds/mo free tier, 12 mo)
// ============================================================================

targetScope = 'resourceGroup'

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

@description('Mandatory tags applied to all resources.')
param tags object

@description('Whether to allow public network access.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Disabled'

@description('Home IP address to allow when publicNetworkAccess is Enabled. Ignored when Disabled.')
param allowedIpAddress string = ''

@description('Object ID of the Entra user or group to set as SQL Active Directory admin.')
param azureAdAdminObjectId string

@description('Resource ID of the shared Log Analytics workspace.')
param logAnalyticsWorkspaceId string

var orgPrefix = 'nx'
var regionShort = location == 'swedencentral' ? 'swc' : 'weu'
var serverName = '${orgPrefix}-${environmentName}-${workload}-${regionShort}-sql-${instance}'
var dbName = 'nordlux-db'

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: 'cloud-admin'
      sid: azureAdAdminObjectId
      tenantId: subscription().tenantId
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: publicNetworkAccess
  }
}

// 0.0.0.0/0.0.0.0 is the special Azure Services allow rule in SQL firewall
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2021-11-01' = if (publicNetworkAccess == 'Enabled') {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource allowHomeIp 'Microsoft.Sql/servers/firewallRules@2021-11-01' = if (publicNetworkAccess == 'Enabled' && !empty(allowedIpAddress)) {
  parent: sqlServer
  name: 'AllowHomeIp'
  properties: {
    startIpAddress: allowedIpAddress
    endIpAddress: allowedIpAddress
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: dbName
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5_1'
  }
  properties: {
    autoPauseDelay: 60
    minCapacity: json('0.5')
    maxSizeBytes: 34359738368
    zoneRedundant: false
    requestedBackupStorageRedundancy: 'Local'
  }
}

// SQL Server has no supported diagnostic log categories at the server level;
// audit events are configured via auditingSettings, not diagnostic settings.
resource serverDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${serverName}-diag'
  scope: sqlServer
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

resource dbDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${dbName}-diag'
  scope: database
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'Errors', enabled: true }
      { category: 'QueryStoreRuntimeStatistics', enabled: true }
    ]
    metrics: [
      { category: 'Basic', enabled: true }
    ]
  }
}

output serverId   string = sqlServer.id
output serverName string = sqlServer.name
output serverFqdn string = sqlServer.properties.fullyQualifiedDomainName
output databaseName string = database.name
