// ============================================================================
// Module: ai/main
// Purpose: Deploys nx-prod-ai-rg with Azure OpenAI and AI Search for the
//          Trail Buddy RAG feature (Week 4).
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-25
// Cost impact: per-use (OpenAI tokens) + free (AI Search Free SKU)
// ============================================================================
targetScope = 'subscription'

@description('Your email address — used in Owner tag.')
param ownerEmail string = 'sam.lekkla@outlook.com'

@description('Azure region for all resources.')
@allowed(['swedencentral', 'westeurope'])
param location string = 'swedencentral'

@description('Three-digit instance counter, zero-padded.')
@minLength(3)
@maxLength(3)
param instance string = '001'

var subId          = subscription().subscriptionId
var logAnalyticsId = '/subscriptions/${subId}/resourceGroups/nx-shared-obs-rg/providers/Microsoft.OperationalInsights/workspaces/nx-shared-obs-swc-log-001'

var sharedTags = {
  Environment: 'prod'
  Workload:    'ai'
  CostCenter:  'aurora-portfolio'
  Owner:       ownerEmail
}

resource aiRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name:     'nx-prod-ai-rg'
  location: location
  tags:     sharedTags
}

module openAi 'modules/openai.bicep' = {
  name:  'deploy-prod-oai'
  scope: aiRg
  params: {
    environmentName:         'prod'
    workload:                'ai'
    location:                location
    instance:                instance
    logAnalyticsWorkspaceId: logAnalyticsId
    tags:                    sharedTags
  }
}

module aiSearch 'modules/ai-search.bicep' = {
  name:  'deploy-prod-srch'
  scope: aiRg
  params: {
    environmentName:         'prod'
    workload:                'ai'
    location:                location
    instance:                instance
    logAnalyticsWorkspaceId: logAnalyticsId
    tags:                    sharedTags
  }
}

output openAiEndpoint string = openAi.outputs.endpoint
output openAiName     string = openAi.outputs.name
output searchEndpoint string = aiSearch.outputs.endpoint
output searchName     string = aiSearch.outputs.name
