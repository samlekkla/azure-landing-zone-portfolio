// ============================================================================
// Module: keyvault
// Purpose: Deploys a Key Vault with RBAC authorization and diagnostic settings.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-24
// Cost impact: ~$0.03 per 10k operations
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

@description('Resource ID of the shared Log Analytics workspace.')
param logAnalyticsWorkspaceId string

var orgPrefix = 'nx'
var regionShort = location == 'swedencentral' ? 'swc' : 'weu'
// nx-dev-sec-swc-kv-001 = 22 chars | nx-prod-sec-swc-kv-001 = 23 chars — both ≤24
var kvName = '${orgPrefix}-${environmentName}-sec-${regionShort}-kv-${instance}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      // AzureServices bypass allows trusted first-party services (e.g. ARM deployments)
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: publicNetworkAccess == 'Enabled' && !empty(allowedIpAddress)
        ? [{ value: '${allowedIpAddress}/32' }]
        : []
      virtualNetworkRules: []
    }
  }
}

// diagnosticSettings has no stable GA API version in Azure — preview is the only option
resource kvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${kvName}-diag'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
