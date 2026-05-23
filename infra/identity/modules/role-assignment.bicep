// ============================================================================
// Module: role-assignment
// Purpose: Assigns a built-in RBAC role to a principal at resource-group scope
// Owner: you@example.com
// Last reviewed: 2026-05-21
// Cost impact: free
// ============================================================================

targetScope = 'resourceGroup'

@description('Principal ID (objectId) of the MI or service principal.')
param principalId string

@description('Built-in role definition ID (GUID only).')
param roleDefinitionId string

@description('Principal type.')
@allowed(['ServicePrincipal', 'User', 'Group'])
param principalType string = 'ServicePrincipal'

var roleAssignmentName = guid(resourceGroup().id, principalId, roleDefinitionId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = roleAssignment.id
