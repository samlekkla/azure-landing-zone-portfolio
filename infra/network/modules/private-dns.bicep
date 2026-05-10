// ============================================================================
// Module: private-dns
// Purpose: Private DNS zone + links to provided VNets.
// Owner: samlekkla
// Last reviewed: 2026-05-09
// Cost impact: free (under 25 zones); links free
// ============================================================================

targetScope = 'resourceGroup'

param zoneName string
param vnetIds array
param tags object

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: zoneName
  location: 'global'
  tags: tags
}

resource links 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for (vnetId, i) in vnetIds: {
  parent: zone
  name: 'link-${i}'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}]

output id string = zone.id
output name string = zone.name
