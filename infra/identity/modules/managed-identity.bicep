// ============================================================================
// Module: managed-identity
// Purpose: Creates a user-assigned managed identity for CI/CD pipeline auth
// Owner: you@example.com
// Last reviewed: 2026-05-21
// Cost impact: free
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

var orgPrefix = 'nx'
var regionShort = location == 'swedencentral' ? 'swc' : 'weu'
var miName = '${orgPrefix}-${environmentName}-${workload}-${regionShort}-mi-${instance}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: miName
  location: location
  tags: tags
}

output id string = managedIdentity.id
output name string = managedIdentity.name
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
