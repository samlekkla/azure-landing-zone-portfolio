// ============================================================================
// Module: private-endpoint
// Purpose: Deploys a Private Endpoint and DNS Zone Group for a PaaS service.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-24
// Cost impact: ~$7/mo per endpoint
// ============================================================================

targetScope = 'resourceGroup'

@description('Environment short name.')
@allowed(['dev', 'prod', 'shared'])
param environmentName string

@description('Workload short name.')
@allowed(['web', 'api', 'data', 'ai', 'obs', 'net', 'sec', 'gov'])
param workload string

@description('Azure region.')
@allowed(['swedencentral', 'westeurope'])
param location string = 'swedencentral'

@description('Three-digit instance counter, zero-padded.')
@minLength(3)
@maxLength(3)
param instance string = '001'

@description('Mandatory tags applied to all resources.')
param tags object

@description('Resource ID of the service to connect (e.g. Key Vault id).')
param serviceId string

@description('Private Link subresource group ID (e.g. vault for Key Vault).')
param serviceGroupId string

@description('Resource ID of the subnet for the private endpoint.')
param subnetId string

@description('Resource ID of the Private DNS Zone to link.')
param privateDnsZoneId string

@description('Resource ID of the shared Log Analytics workspace (reserved for future use — PEs do not support diagnostic settings).')
param logAnalyticsWorkspaceId string

var orgPrefix = 'nx'
var regionShort = location == 'swedencentral' ? 'swc' : 'weu'
var peName = '${orgPrefix}-${environmentName}-sec-${regionShort}-pe-${instance}'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: peName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: peName
        properties: {
          privateLinkServiceId: serviceId
          groupIds: [serviceGroupId]
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output id string = privateEndpoint.id
output name string = privateEndpoint.name
output customDnsConfigs array = privateEndpoint.properties.customDnsConfigs
