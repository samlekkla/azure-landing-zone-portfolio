// ============================================================================
// Module: policy-assignments
// Purpose: Assigns built-in policies to enforce allowed locations and required tags.
// Owner: <your-handle>
// Last reviewed: 2026-05-08
// Cost impact: free (Azure Policy is always free)
// ============================================================================

targetScope = 'subscription'

param allowedLocations array = [
  'swedencentral'
  'westeurope'
]

param requiredTags array = [
  'Environment'
  'Workload'
  'CostCenter'
  'Owner'
]

// Built-in policy definition IDs (these are fixed Azure GUIDs, same for everyone)
var allowedLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
var requireTagPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99'

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'aurora-allowed-locations'
  properties: {
    displayName: 'Aurora — Allowed locations'
    policyDefinitionId: allowedLocationsPolicyId
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
    enforcementMode: 'Default'
  }
}

resource requireTagsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = [for tagName in requiredTags: {
  name: 'aurora-require-tag-${toLower(tagName)}'
  properties: {
    displayName: 'Aurora — Require tag: ${tagName}'
    policyDefinitionId: requireTagPolicyId
    parameters: {
      tagName: {
        value: tagName
      }
    }
    enforcementMode: 'Default'
  }
}]
