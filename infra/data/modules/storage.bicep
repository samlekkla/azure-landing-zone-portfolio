// ============================================================================
// Module: storage
// Purpose: Deploys a StorageV2 account with managed-identity-only access and
//          blob soft delete. Blob service logs ship to central Log Analytics.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-24
// Cost impact: free (5 GB Hot LRS, 12 mo free tier)
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

var regionShort = location == 'swedencentral' ? 'swc' : 'weu'
// nxdevdataswcst001 = 17 chars | nxproddataswcst001 = 18 chars — both ≤24, no hyphens
var saName = 'nx${environmentName}${workload}${regionShort}st${instance}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: saName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: publicNetworkAccess == 'Enabled' && !empty(allowedIpAddress)
        ? [{ action: 'Allow', value: allowedIpAddress }]
        : []
      virtualNetworkRules: []
    }
  }
}

// Blob service — soft delete + container soft delete + diagnostic logs
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// diagnosticSettings has no stable GA API version in Azure — preview is the only option
resource blobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${saName}-blob-diag'
  scope: blobService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'StorageRead',   enabled: true }
      { category: 'StorageWrite',  enabled: true }
      { category: 'StorageDelete', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
