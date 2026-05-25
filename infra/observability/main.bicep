// ============================================================================
// Module: observability/main
// Purpose: Deploys scheduled query alert rules to nx-shared-obs-rg.
//          Covers admin sign-in, Key Vault, App Service, SQL, and Defender.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-25
// Cost impact: free (Log Analytics alert rules included in workspace)
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

var subId = subscription().subscriptionId

var logAnalyticsId = '/subscriptions/${subId}/resourceGroups/nx-shared-obs-rg/providers/Microsoft.OperationalInsights/workspaces/nx-shared-obs-swc-log-001'
var actionGroupId  = '/subscriptions/${subId}/resourceGroups/nx-shared-gov-rg/providers/Microsoft.Insights/actionGroups/nx-shared-gov-swc-ag-001'

var sharedTags = {
  Environment: 'shared'
  Workload:    'obs'
  CostCenter:  'aurora-portfolio'
  Owner:       ownerEmail
}

resource obsRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: 'nx-shared-obs-rg'
}

module alertRules 'modules/alert-rules.bicep' = {
  name:  'deploy-shared-alert-rules'
  scope: obsRg
  params: {
    environmentName:        'shared'
    workload:               'obs'
    location:               location
    instance:               instance
    logAnalyticsWorkspaceId: logAnalyticsId
    actionGroupId:           actionGroupId
    tags:                    sharedTags
  }
}

output alertIds array = alertRules.outputs.alertIds
