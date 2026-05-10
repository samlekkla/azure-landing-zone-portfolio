// ============================================================================
// Module: vnet
// Purpose: Deploy a VNet with subnets. Reusable across hub and spokes.
// Owner: samlekkla
// Last reviewed: 2026-05-09
// Cost impact: free (VNet itself; peering data charged separately)
// ============================================================================

targetScope = 'resourceGroup'

param vnetName string
param location string
param tags object
param addressPrefix string
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          delegations: contains(subnet, 'delegation')
            ? [
                {
                  name: 'delegation'
                  properties: {
                    serviceName: subnet.delegation
                  }
                }
              ]
            : []
          networkSecurityGroup: contains(subnet, 'nsgId')
            ? {
                id: subnet.nsgId
              }
            : null
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

output id string = vnet.id
output name string = vnet.name
output subnetIds array = [
  for (subnet, i) in subnets: {
    name: subnet.name
    id: vnet.properties.subnets[i].id
  }
]
