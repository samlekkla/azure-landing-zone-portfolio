// ============================================================================
// Module: nsg
// Purpose: NSG with default-deny baseline. Reusable per subnet.
// Owner: samlekkla
// Last reviewed: 2026-05-09
// Cost impact: free
// ============================================================================

targetScope = 'resourceGroup'

param nsgName string
param location string
param tags object

@description('Additional rules beyond the baseline. Empty array = baseline only.')
param additionalRules array = []

var baselineRules = [
  {
    name: 'Allow-AzureLoadBalancer-In'
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: 'AzureLoadBalancer'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
  {
    name: 'Allow-VNet-In'
    properties: {
      priority: 110
      direction: 'Inbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRange: '*'
    }
  }
  {
    name: 'Deny-AllInbound'
    properties: {
      priority: 4000
      direction: 'Inbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
  {
    name: 'Allow-VNet-Out'
    properties: {
      priority: 100
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRange: '*'
    }
  }
  {
    name: 'Allow-AzureMonitor-Out'
    properties: {
      priority: 110
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: 'AzureMonitor'
      destinationPortRange: '443'
    }
  }
  {
    name: 'Allow-Storage-Out'
    properties: {
      priority: 120
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: 'Storage'
      destinationPortRange: '443'
    }
  }
  {
    name: 'Deny-AllOutbound'
    properties: {
      priority: 4000
      direction: 'Outbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
]

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: concat(baselineRules, additionalRules)
  }
}

output id string = nsg.id
output name string = nsg.name
