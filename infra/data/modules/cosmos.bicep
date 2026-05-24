// ============================================================================
// Module: cosmos
// Purpose: Deploys a Cosmos DB free-tier account (GlobalDocumentDB) with a
//          single database and container. Single region only — multi-region
//          would exit free tier.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-24
// Cost impact: free (1000 RU/s + 25 GB free tier — one per subscription, 12 mo)
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

@description('Resource ID of the shared Log Analytics workspace.')
param logAnalyticsWorkspaceId string

var orgPrefix = 'nx'
var regionShort = location == 'swedencentral' ? 'swc' : 'weu'
var accountName = '${orgPrefix}-${environmentName}-${workload}-${regionShort}-cosmos-${instance}'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: accountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableFreeTier: true
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    enableAnalyticalStorage: false
    backupPolicy: {
      type: 'Continuous'
      continuousModeProperties: {
        tier: 'Continuous7Days'
      }
    }
    // TODO: set to true once managed identity access to this account is verified
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
    ipRules: []
  }
}

resource catalogDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = {
  parent: cosmosAccount
  name: 'nordlux-catalog'
  properties: {
    resource: {
      id: 'nordlux-catalog'
    }
  }
}

resource productsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  parent: catalogDatabase
  name: 'products'
  properties: {
    resource: {
      id: 'products'
      partitionKey: {
        paths: ['/categoryId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          { path: '/*' }
        ]
        excludedPaths: [
          { path: '/"_etag"/?' }
        ]
      }
    }
    options: {
      throughput: 400
    }
  }
}

resource cosmosDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${accountName}-diag'
  scope: cosmosAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'DataPlaneRequests', enabled: true }
      { category: 'QueryRuntimeStatistics', enabled: true }
    ]
    metrics: [
      { category: 'Requests', enabled: true }
    ]
  }
}

output id       string = cosmosAccount.id
output name     string = cosmosAccount.name
output endpoint string = cosmosAccount.properties.documentEndpoint
