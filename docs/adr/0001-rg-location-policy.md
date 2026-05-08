# ADR 0001 — Defer RG-location policy enforcement

**Status:** Accepted
**Date:** 2026-05-08
**Deciders:** <your-handle>

## Context

Azure's built-in "Allowed locations" policy
(`e56962a6-4747-49cd-b67b-bf8b01975c4c`) does not apply to resource
groups by design. RGs are global metadata objects whose `location`
field stores only deployment-record metadata, not the placement of
resources inside.

Aurora restricts allowed regions to `swedencentral` and `westeurope`
per `02_naming_and_tagging.md`. The current policy assignment blocks
non-compliant *resources* but allows RGs to be created in any region.

## Decision

Defer the second policy ("Allowed locations for resource groups",
`e765b5de-1225-4ba3-bd56-1ac6695af988`) to a future iteration.

## Rationale

- All resources inside RGs are already blocked by the existing assignment.
- A misplaced RG with no resources has zero cost impact.
- Adding a second assignment now adds noise without security or cost value
  for a four-week portfolio project.

## Consequences

- An empty RG can be created in any region.
- A resource deployment into that RG will still fail policy.
- Documented as a known gap in the threat model.

## Future work

Add the second policy assignment to `policy-assignments.bicep`:

```bicep
var rgLocationPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988'

resource rgLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'aurora-allowed-rg-locations'
  properties: {
    displayName: 'Aurora — Allowed locations for resource groups'
    policyDefinitionId: rgLocationPolicyId
    parameters: {
      listOfAllowedLocations: { value: allowedLocations }
    }
    enforcementMode: 'Default'
  }
}
```