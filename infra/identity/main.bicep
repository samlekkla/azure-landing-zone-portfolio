// ============================================================================
// Module: identity/main
// Purpose: Bootstrap CI/CD managed identities for dev and prod pipelines.
//          Deploys gov RGs, user-assigned MIs, workload RGs, and role assignments.
//          Run once manually — pipeline takes over after.
// Owner: you@example.com
// Last reviewed: 2026-05-21
// Cost impact: free
// ============================================================================

targetScope = 'subscription'

@description('Azure region for all resources.')
@allowed(['swedencentral', 'westeurope'])
param location string = 'swedencentral'

@description('Your email address — used in Owner tag.')
param ownerEmail string = 'you@example.com'

var contributorRoleId     = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var userAccessAdminRoleId = '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'

var sharedTags = {
  CostCenter: 'aurora-portfolio'
  Owner: ownerEmail
  DeployedBy: 'bicep'
}

// ---------------------------------------------------------------------------
// Resource Groups
// ---------------------------------------------------------------------------
resource devGovRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'nx-dev-gov-rg'
  location: location
  tags: union(sharedTags, { Environment: 'dev', Workload: 'gov' })
}

resource prodGovRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'nx-prod-gov-rg'
  location: location
  tags: union(sharedTags, { Environment: 'prod', Workload: 'gov' })
}

resource devWebRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'nx-dev-web-rg'
  location: location
  tags: union(sharedTags, { Environment: 'dev', Workload: 'web' })
}

resource devDataRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'nx-dev-data-rg'
  location: location
  tags: union(sharedTags, { Environment: 'dev', Workload: 'data' })
}

resource devSecRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'nx-dev-sec-rg'
  location: location
  tags: union(sharedTags, { Environment: 'dev', Workload: 'sec' })
}

resource prodWebRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'nx-prod-web-rg'
  location: location
  tags: union(sharedTags, { Environment: 'prod', Workload: 'web' })
}

resource prodDataRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'nx-prod-data-rg'
  location: location
  tags: union(sharedTags, { Environment: 'prod', Workload: 'data' })
}

resource prodSecRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'nx-prod-sec-rg'
  location: location
  tags: union(sharedTags, { Environment: 'prod', Workload: 'sec' })
}

// ---------------------------------------------------------------------------
// Managed Identities
// ---------------------------------------------------------------------------
module devMi 'modules/managed-identity.bicep' = {
  name: 'deploy-dev-gov-mi'
  scope: devGovRg
  params: {
    environmentName: 'dev'
    workload: 'gov'
    location: location
    instance: '001'
    tags: union(sharedTags, { Environment: 'dev', Workload: 'gov' })
  }
}

module prodMi 'modules/managed-identity.bicep' = {
  name: 'deploy-prod-gov-mi'
  scope: prodGovRg
  params: {
    environmentName: 'prod'
    workload: 'gov'
    location: location
    instance: '001'
    tags: union(sharedTags, { Environment: 'prod', Workload: 'gov' })
  }
}

// ---------------------------------------------------------------------------
// Role assignments — dev MI on dev workload RGs
// ---------------------------------------------------------------------------
module devMiContribWeb 'modules/role-assignment.bicep' = {
  name: 'ra-dev-mi-contrib-web'
  scope: devWebRg
  params: { principalId: devMi.outputs.principalId, roleDefinitionId: contributorRoleId }
}

module devMiUaaWeb 'modules/role-assignment.bicep' = {
  name: 'ra-dev-mi-uaa-web'
  scope: devWebRg
  params: { principalId: devMi.outputs.principalId, roleDefinitionId: userAccessAdminRoleId }
}

module devMiContribData 'modules/role-assignment.bicep' = {
  name: 'ra-dev-mi-contrib-data'
  scope: devDataRg
  params: { principalId: devMi.outputs.principalId, roleDefinitionId: contributorRoleId }
}

module devMiUaaData 'modules/role-assignment.bicep' = {
  name: 'ra-dev-mi-uaa-data'
  scope: devDataRg
  params: { principalId: devMi.outputs.principalId, roleDefinitionId: userAccessAdminRoleId }
}

module devMiContribSec 'modules/role-assignment.bicep' = {
  name: 'ra-dev-mi-contrib-sec'
  scope: devSecRg
  params: { principalId: devMi.outputs.principalId, roleDefinitionId: contributorRoleId }
}

module devMiUaaSec 'modules/role-assignment.bicep' = {
  name: 'ra-dev-mi-uaa-sec'
  scope: devSecRg
  params: { principalId: devMi.outputs.principalId, roleDefinitionId: userAccessAdminRoleId }
}

// ---------------------------------------------------------------------------
// Role assignments — prod MI on prod workload RGs
// ---------------------------------------------------------------------------
module prodMiContribWeb 'modules/role-assignment.bicep' = {
  name: 'ra-prod-mi-contrib-web'
  scope: prodWebRg
  params: { principalId: prodMi.outputs.principalId, roleDefinitionId: contributorRoleId }
}

module prodMiUaaWeb 'modules/role-assignment.bicep' = {
  name: 'ra-prod-mi-uaa-web'
  scope: prodWebRg
  params: { principalId: prodMi.outputs.principalId, roleDefinitionId: userAccessAdminRoleId }
}

module prodMiContribData 'modules/role-assignment.bicep' = {
  name: 'ra-prod-mi-contrib-data'
  scope: prodDataRg
  params: { principalId: prodMi.outputs.principalId, roleDefinitionId: contributorRoleId }
}

module prodMiUaaData 'modules/role-assignment.bicep' = {
  name: 'ra-prod-mi-uaa-data'
  scope: prodDataRg
  params: { principalId: prodMi.outputs.principalId, roleDefinitionId: userAccessAdminRoleId }
}

module prodMiContribSec 'modules/role-assignment.bicep' = {
  name: 'ra-prod-mi-contrib-sec'
  scope: prodSecRg
  params: { principalId: prodMi.outputs.principalId, roleDefinitionId: contributorRoleId }
}

module prodMiUaaSec 'modules/role-assignment.bicep' = {
  name: 'ra-prod-mi-uaa-sec'
  scope: prodSecRg
  params: { principalId: prodMi.outputs.principalId, roleDefinitionId: userAccessAdminRoleId }
}

// ---------------------------------------------------------------------------
// Outputs — needed for federated credentials and GitHub secrets
// ---------------------------------------------------------------------------
output devMiClientId string = devMi.outputs.clientId
output devMiPrincipalId string = devMi.outputs.principalId
output prodMiClientId string = prodMi.outputs.clientId
output prodMiPrincipalId string = prodMi.outputs.principalId
# test
