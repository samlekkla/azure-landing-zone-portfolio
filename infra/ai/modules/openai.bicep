// ============================================================================
// Module: ai/modules/openai
// Purpose: Deploys Azure OpenAI account with gpt-4o-mini and
//          text-embedding-3-small model deployments.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-25
// Cost impact: per-use (tokens only) — no base cost on S0
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
var oaiName     = '${orgPrefix}-${environmentName}-${workload}-${regionShort}-oai-${instance}'

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name:     oaiName
  location: location
  tags:     tags
  kind:     'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess:  'Enabled'
    customSubDomainName:  '${orgPrefix}-${environmentName}-${workload}-${regionShort}-oai-${instance}'
  }
}

resource deployGpt4oMini 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAiAccount
  name:   'gpt-4o-mini'
  sku: {
    name:     'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format:  'OpenAI'
      name:    'gpt-4.1-mini'
      version: '2025-04-14'
    }
  }
}

resource deployEmbedding 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent:    openAiAccount
  name:      'text-embedding-3-small'
  dependsOn: [deployGpt4oMini]
  sku: {
    name:     'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format:  'OpenAI'
      name:    'text-embedding-3-small'
      version: '1'
    }
  }
}

resource oaiDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name:  '${oaiName}-diag'
  scope: openAiAccount
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

output id       string = openAiAccount.id
output name     string = openAiAccount.name
output endpoint string = openAiAccount.properties.endpoint
