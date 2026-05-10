// ============================================================================
// Module: main (governance)
// Purpose: Bootstraps governance RG, action group, subscription budget,
//          policies, observability RG and Log Analytics workspace.
// Owner: samlekkla
// Last reviewed: 2026-05-08
// Cost impact: free
// ============================================================================

targetScope = 'subscription'

param location string = 'swedencentral'
param ownerEmail string
param budgetAmount int
param budgetStartDate string

var rgName = 'nx-shared-gov-rg'
var actionGroupName = 'nx-shared-gov-swc-ag-001'
var budgetName = 'nx-shared-gov-swc-bdgt-001'

var obsRgName = 'nx-shared-obs-rg'
var workspaceName = 'nx-shared-obs-swc-log-001'

var tags = {
  Environment: 'shared'
  Workload: 'gov'
  CostCenter: 'aurora-portfolio'
  Owner: ownerEmail
}

var obsTags = {
  Environment: 'shared'
  Workload: 'obs'
  CostCenter: 'aurora-portfolio'
  Owner: ownerEmail
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

resource obsRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: obsRgName
  location: location
  tags: obsTags
}

module actionGroup 'modules/action-group.bicep' = {
  name: 'deploy-action-group'
  scope: rg
  params: {
    actionGroupName: actionGroupName
    ownerEmail: ownerEmail
    tags: tags
  }
}

module budget 'modules/budget.bicep' = {
  name: 'deploy-budget'
  params: {
    budgetName: budgetName
    amount: budgetAmount
    startDate: budgetStartDate
    contactEmails: [ownerEmail]
    actionGroupId: actionGroup.outputs.id
  }
}

module policies 'modules/policy-assignments.bicep' = {
  name: 'deploy-policies'
}

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'deploy-log-analytics'
  scope: obsRg
  params: {
    workspaceName: workspaceName
    location: location
    tags: obsTags
  }
}
