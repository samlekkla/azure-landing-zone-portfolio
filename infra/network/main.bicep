// ============================================================================
// Module: network/main
// Purpose: Deploys hub + 2 spoke VNets, their RGs, and baseline NSGs per subnet.
// Owner: samlekkla
// Last reviewed: 2026-05-09
// Cost impact: free (VNets + NSGs free; peering data added later ~$3/mo)
// ============================================================================

targetScope = 'subscription'

param location string = 'swedencentral'
param ownerEmail string

// Tag objects for each workload 
var hubTags = {
  Environment: 'shared'
  Workload: 'net'
  CostCenter: 'aurora-portfolio'
  Owner: ownerEmail
}

var devTags = {
  Environment: 'dev'
  Workload: 'net'
  CostCenter: 'aurora-portfolio'
  Owner: ownerEmail
}

var prodTags = {
  Environment: 'prod'
  Workload: 'net'
  CostCenter: 'aurora-portfolio'
  Owner: ownerEmail
}

// Resource group names 
var hubRgName = 'nx-shared-net-rg'
var devRgName = 'nx-dev-net-rg'
var prodRgName = 'nx-prod-net-rg'

// VNet names 
var hubVnetName = 'nx-shared-net-swc-vnet-001'
var devVnetName = 'nx-dev-net-swc-vnet-001'
var prodVnetName = 'nx-prod-net-swc-vnet-001'

// Hub subnets (10.10.0.0/16)
var hubSubnets = [
  {
    name: 'snet-shared'
    addressPrefix: '10.10.3.0/24'
  }
  {
    name: 'snet-mgmt'
    addressPrefix: '10.10.4.0/24'
  }
]

// Dev spoke subnets (10.20.0.0/16) 
var devSubnets = [
  {
    name: 'snet-app'
    addressPrefix: '10.20.1.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  {
    name: 'snet-data'
    addressPrefix: '10.20.2.0/24'
  }
  {
    name: 'snet-test'
    addressPrefix: '10.20.3.0/24'
  }
]

// Prod spoke subnets (10.30.0.0/16) 
var prodSubnets = [
  {
    name: 'snet-app'
    addressPrefix: '10.30.1.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  {
    name: 'snet-data'
    addressPrefix: '10.30.2.0/24'
  }
  {
    name: 'snet-pe'
    addressPrefix: '10.30.3.0/24'
  }
  {
    name: 'snet-aca'
    addressPrefix: '10.30.4.0/23'
    delegation: 'Microsoft.App/environments'
  }
]

// Resource groups 
resource hubRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: hubRgName
  location: location
  tags: hubTags
}

resource devRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: devRgName
  location: location
  tags: devTags
}

resource prodRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: prodRgName
  location: location
  tags: prodTags
}

// ── NSGs (deploy first; subnets attach to them) ─────────────────────────────
module hubNsgs 'modules/nsg.bicep' = [
  for subnet in hubSubnets: {
    name: 'deploy-hub-nsg-${subnet.name}'
    scope: hubRg
    params: {
      nsgName: 'nx-shared-net-swc-nsg-${subnet.name}'
      location: location
      tags: hubTags
    }
  }
]

module devNsgs 'modules/nsg.bicep' = [
  for subnet in devSubnets: {
    name: 'deploy-dev-nsg-${subnet.name}'
    scope: devRg
    params: {
      nsgName: 'nx-dev-net-swc-nsg-${subnet.name}'
      location: location
      tags: devTags
    }
  }
]

module prodNsgs 'modules/nsg.bicep' = [
  for subnet in prodSubnets: {
    name: 'deploy-prod-nsg-${subnet.name}'
    scope: prodRg
    params: {
      nsgName: 'nx-prod-net-swc-nsg-${subnet.name}'
      location: location
      tags: prodTags
    }
  }
]

// Subnet arrays with NSG IDs attached 
var hubSubnetsWithNsg = [
  for subnet in hubSubnets: union(subnet, {
    nsgId: resourceId(
      subscription().subscriptionId,
      hubRgName,
      'Microsoft.Network/networkSecurityGroups',
      'nx-shared-net-swc-nsg-${subnet.name}'
    )
  })
]

var devSubnetsWithNsg = [
  for subnet in devSubnets: union(subnet, {
    nsgId: resourceId(
      subscription().subscriptionId,
      devRgName,
      'Microsoft.Network/networkSecurityGroups',
      'nx-dev-net-swc-nsg-${subnet.name}'
    )
  })
]

var prodSubnetsWithNsg = [
  for subnet in prodSubnets: union(subnet, {
    nsgId: resourceId(
      subscription().subscriptionId,
      prodRgName,
      'Microsoft.Network/networkSecurityGroups',
      'nx-prod-net-swc-nsg-${subnet.name}'
    )
  })
]

// -VNets 
module hubVnet 'modules/vnet.bicep' = {
  name: 'deploy-hub-vnet'
  scope: hubRg
  dependsOn: [
    hubNsgs
  ]
  params: {
    vnetName: hubVnetName
    location: location
    tags: hubTags
    addressPrefix: '10.10.0.0/16'
    subnets: hubSubnetsWithNsg
  }
}

module devVnet 'modules/vnet.bicep' = {
  name: 'deploy-dev-vnet'
  scope: devRg
  dependsOn: [
    devNsgs
  ]
  params: {
    vnetName: devVnetName
    location: location
    tags: devTags
    addressPrefix: '10.20.0.0/16'
    subnets: devSubnetsWithNsg
  }
}

module prodVnet 'modules/vnet.bicep' = {
  name: 'deploy-prod-vnet'
  scope: prodRg
  dependsOn: [
    prodNsgs
  ]
  params: {
    vnetName: prodVnetName
    location: location
    tags: prodTags
    addressPrefix: '10.30.0.0/16'
    subnets: prodSubnetsWithNsg
  }
}

// - VNet peering (Hub ↔ Dev) 
module peerHubToDev 'modules/peering.bicep' = {
  name: 'deploy-peer-hub-to-dev'
  scope: hubRg
  params: {
    peeringName: 'hub-to-dev'
    localVnetName: hubVnetName
    remoteVnetId: devVnet.outputs.id
  }
}

module peerDevToHub 'modules/peering.bicep' = {
  name: 'deploy-peer-dev-to-hub'
  scope: devRg
  params: {
    peeringName: 'dev-to-hub'
    localVnetName: devVnetName
    remoteVnetId: hubVnet.outputs.id
  }
}

// - VNet peering (Hub ↔ Prod)
module peerHubToProd 'modules/peering.bicep' = {
  name: 'deploy-peer-hub-to-prod'
  scope: hubRg
  params: {
    peeringName: 'hub-to-prod'
    localVnetName: hubVnetName
    remoteVnetId: prodVnet.outputs.id
  }
}

module peerProdToHub 'modules/peering.bicep' = {
  name: 'deploy-peer-prod-to-hub'
  scope: prodRg
  params: {
    peeringName: 'prod-to-hub'
    localVnetName: prodVnetName
    remoteVnetId: hubVnet.outputs.id
  }
}

// - Private DNS zones (in hub RG, linked to all 3 VNets) 
var privateDnsZones = [
  'privatelink.database.windows.net'
  'privatelink.azurewebsites.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.documents.azure.com'
  'privatelink.openai.azure.com'
  'privatelink.search.windows.net'
]

module dnsZones 'modules/private-dns.bicep' = [for zone in privateDnsZones: {
  name: 'deploy-dns-${replace(zone, '.', '-')}'
  scope: hubRg
  params: {
    zoneName: zone
    vnetIds: [
      hubVnet.outputs.id
      devVnet.outputs.id
      prodVnet.outputs.id
    ]
    tags: hubTags
  }
}]
