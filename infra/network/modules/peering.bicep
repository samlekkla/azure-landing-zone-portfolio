// ============================================================================
// Module: peering
// Purpose: One-way VNet peering. Call twice for bidirectional.
// Owner: samlekkla
// Last reviewed: 2026-05-09
// Cost impact: peering data ~$0.01/GB processed
// ============================================================================

targetScope = 'resourceGroup'

param peeringName string
param localVnetName string
param remoteVnetId string

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: '${localVnetName}/${peeringName}'
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

output id string = peering.id
