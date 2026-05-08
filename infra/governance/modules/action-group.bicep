// ============================================================================
// Module: action-group
// Purpose: Action group that delivers budget and monitor alerts to the project owner.
// Owner: <your-handle>
// Last reviewed: 2026-05-08
// Cost impact: free (notifications ~$1/1000 emails — negligible for this project)
// ============================================================================

targetScope = 'resourceGroup'

param actionGroupName string
param ownerEmail string
param tags object

resource ag 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'aurora'
    enabled: true
    emailReceivers: [
      {
        name: 'owner'
        emailAddress: ownerEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

output id string = ag.id
