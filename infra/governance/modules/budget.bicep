// ============================================================================
// Module: budget
// Purpose: Subscription-scoped Cost Management budget with three notifications.
// Owner: samlekkla
// Last reviewed: 2026-05-08
// Cost impact: free (Cost Management is always free)
// ============================================================================

targetScope = 'subscription'

param budgetName string
param amount int
param startDate string
param contactEmails array
param actionGroupId string

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: budgetName
  properties: {
    timePeriod: {
      startDate: startDate
    }
    timeGrain: 'Monthly'
    amount: amount
    category: 'Cost'
    notifications: {
      Actual_50: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: contactEmails
        contactGroups: [ actionGroupId ]
      }
      Forecasted_80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Forecasted'
        contactEmails: contactEmails
        contactGroups: [ actionGroupId ]
      }
      Actual_100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Actual'
        contactEmails: contactEmails
        contactGroups: [ actionGroupId ]
      }
    }
  }
}

output id string = budget.id
