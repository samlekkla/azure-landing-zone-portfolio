// ============================================================================
// Module: ai/modules/ai-search
// Purpose: Deploys Azure AI Search Free SKU for RAG vector index.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-25
// Cost impact: free (Free SKU — 50 MB, 3 indexes, always free)
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

var orgPrefix   = 'nx'
var regionShort = location == 'swedencentral' ? 'swc' : 'weu'
var searchName  = '${orgPrefix}-${environmentName}-${workload}-${regionShort}-srch-${instance}'

resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name:     searchName
  location: location
  tags:     tags
  sku: {
    name: 'free'
  }
  properties: {
    replicaCount:         1
    partitionCount:       1
    hostingMode:          'default'
    publicNetworkAccess:  'enabled'
  }
}

resource searchDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  '${searchName}-diag'
  scope: searchService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { categoryGroup: 'allLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}

output id       string = searchService.id
output name     string = searchService.name
output endpoint string = 'https://${searchService.name}.search.windows.net'
