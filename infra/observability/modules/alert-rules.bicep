// ============================================================================
// Module: observability/modules/alert-rules
// Purpose: Deploys 5 scheduled query alert rules covering admin sign-in,
//          Key Vault, App Service, SQL, and Defender for Cloud.
// Owner: sam.lekkla@outlook.com
// Last reviewed: 2026-05-25
// Cost impact: free (Log Analytics alert rules — included in workspace)
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

@description('Resource ID of the Log Analytics workspace used as alert scope.')
param logAnalyticsWorkspaceId string

@description('Resource ID of the action group to notify on alert firing.')
param actionGroupId string

var orgPrefix   = 'nx'
var regionShort = location == 'swedencentral' ? 'swc' : 'weu'
var namePrefix  = '${orgPrefix}-${environmentName}-${workload}-${regionShort}'

var actionGroupList = [actionGroupId]

// ---------------------------------------------------------------------------
// Alert 1 — Admin sign-in failure spike (Sev 1, 5-min freq, 10-min window)
// ---------------------------------------------------------------------------
resource alertAdminSigninFailure 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name:     '${namePrefix}-alert-001'
  location: location
  tags:     tags
  properties: {
    displayName:          'Admin sign-in failure spike'
    description:          'Fires when admin sign-in failures exceed 5 in 10 minutes.'
    severity:             1
    enabled:              true
    autoMitigate:         true
    skipQueryValidation:  true
    evaluationFrequency:  'PT5M'
    windowSize:           'PT10M'
    scopes:               [logAnalyticsWorkspaceId]
    criteria: {
      allOf: [
        {
          query:           'SigninLogs | where TimeGenerated > ago(10m) | where ResultType != "0" | where UserPrincipalName has_any ("sg-cloud-admins") | summarize Count = count() | where Count > 5'
          timeAggregation: 'Count'
          dimensions:      []
          operator:        'GreaterThan'
          threshold:       0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert:  1
          }
        }
      ]
    }
    actions: {
      actionGroups: actionGroupList
    }
  }
}

// ---------------------------------------------------------------------------
// Alert 2 — Key Vault Forbidden burst (Sev 1, 5-min freq, 5-min window)
// ---------------------------------------------------------------------------
resource alertKvForbidden 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name:     '${namePrefix}-alert-002'
  location: location
  tags:     tags
  properties: {
    displayName:          'Key Vault Forbidden burst'
    description:          'Fires when Key Vault Forbidden responses exceed 3 in 5 minutes.'
    severity:             1
    enabled:              true
    autoMitigate:         true
    skipQueryValidation:  true
    evaluationFrequency:  'PT5M'
    windowSize:           'PT5M'
    scopes:               [logAnalyticsWorkspaceId]
    criteria: {
      allOf: [
        {
          query:           'KeyVaultData | where TimeGenerated > ago(5m) | where ResultType == "Forbidden" | summarize Count = count() | where Count > 3'
          timeAggregation: 'Count'
          dimensions:      []
          operator:        'GreaterThan'
          threshold:       0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert:  1
          }
        }
      ]
    }
    actions: {
      actionGroups: actionGroupList
    }
  }
}

// ---------------------------------------------------------------------------
// Alert 3 — App Service 5xx spike (Sev 2, 5-min freq, 5-min window)
// ---------------------------------------------------------------------------
resource alertAppService5xx 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name:     '${namePrefix}-alert-003'
  location: location
  tags:     tags
  properties: {
    displayName:          'App Service 5xx spike'
    description:          'Fires when App Service HTTP 5xx responses exceed 10 in 5 minutes.'
    severity:             2
    enabled:              true
    autoMitigate:         true
    skipQueryValidation:  true
    evaluationFrequency:  'PT5M'
    windowSize:           'PT5M'
    scopes:               [logAnalyticsWorkspaceId]
    criteria: {
      allOf: [
        {
          query:           'AppServiceHTTPLogs | where TimeGenerated > ago(5m) | where ScStatus >= 500 | summarize Count = count() | where Count > 10'
          timeAggregation: 'Count'
          dimensions:      []
          operator:        'GreaterThan'
          threshold:       0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert:  1
          }
        }
      ]
    }
    actions: {
      actionGroups: actionGroupList
    }
  }
}

// ---------------------------------------------------------------------------
// Alert 4 — SQL vCore saturation (Sev 2, 10-min freq, 10-min window)
// ---------------------------------------------------------------------------
resource alertSqlSaturation 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name:     '${namePrefix}-alert-004'
  location: location
  tags:     tags
  properties: {
    displayName:          'SQL vCore saturation'
    description:          'Fires when average SQL CPU exceeds 80% over 10 minutes.'
    severity:             2
    enabled:              true
    autoMitigate:         true
    skipQueryValidation:  true
    evaluationFrequency:  'PT10M'
    windowSize:           'PT10M'
    scopes:               [logAnalyticsWorkspaceId]
    criteria: {
      allOf: [
        {
          query:           'AzureMetrics | where TimeGenerated > ago(10m) | where ResourceProvider == "MICROSOFT.SQL" | where MetricName == "cpu_percent" | summarize AvgCPU = avg(Average) | where AvgCPU > 80'
          timeAggregation: 'Count'
          dimensions:      []
          operator:        'GreaterThan'
          threshold:       0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert:  1
          }
        }
      ]
    }
    actions: {
      actionGroups: actionGroupList
    }
  }
}

// ---------------------------------------------------------------------------
// Alert 5 — Defender High severity recommendation (Sev 2, 1h freq, 1h window)
// ---------------------------------------------------------------------------
resource alertDefenderHigh 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name:     '${namePrefix}-alert-005'
  location: location
  tags:     tags
  properties: {
    displayName:          'Defender for Cloud high severity recommendation'
    description:          'Fires when a new active High severity Defender recommendation appears.'
    severity:             2
    enabled:              true
    autoMitigate:         true
    skipQueryValidation:  true
    evaluationFrequency:  'PT1H'
    windowSize:           'PT1H'
    scopes:               [logAnalyticsWorkspaceId]
    criteria: {
      allOf: [
        {
          query:           'SecurityRecommendation | where TimeGenerated > ago(1h) | where RecommendationSeverity == "High" | where RecommendationState == "Active"'
          timeAggregation: 'Count'
          dimensions:      []
          operator:        'GreaterThan'
          threshold:       0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert:  1
          }
        }
      ]
    }
    actions: {
      actionGroups: actionGroupList
    }
  }
}

output alertIds array = [
  alertAdminSigninFailure.id
  alertKvForbidden.id
  alertAppService5xx.id
  alertSqlSaturation.id
  alertDefenderHigh.id
]
