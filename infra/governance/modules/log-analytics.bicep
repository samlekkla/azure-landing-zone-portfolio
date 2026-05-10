// ============================================================================
// Module: log-analytics
// Purpose: Central Log Analytics workspace for all Aurora diagnostic logs.
// Owner: samlekkla
// Last reviewed: 2026-05-08
// Cost impact: free (5 GB ingestion/mo + 31-day retention free tier)
// ============================================================================

targetScope = 'resourceGroup'

param workspaceName string
param location string
param tags object

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output id string = workspace.id
output name string = workspace.name
