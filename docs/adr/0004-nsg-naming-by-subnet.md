# ADR 0004 — NSG names include subnet name instead of instance counter

**Status:** Accepted
**Date:** 2026-05-09
**Deciders:** samlekkla

## Context

`02_naming_and_tagging.md` defines the resource naming pattern:
`<org>-<env>-<workload>-<region>-<resource>-<instance>`

Strict compliance for NSGs would produce names like
`nx-prod-net-swc-nsg-001`, `nx-prod-net-swc-nsg-002`. With 4 subnets in
prod-spoke, the numbered names give no signal about which subnet each
NSG protects.

## Decision

NSG names use the subnet name in place of the instance counter:
`nx-prod-net-swc-nsg-snet-app` instead of `nx-prod-net-swc-nsg-001`.

## Rationale

- Operational clarity. An on-call engineer reading an alert sees the
  subnet immediately.
- 1:1 mapping between NSG and subnet means an instance counter is
  redundant — there is never a `-002` of the same subnet's NSG.
- Consistent with informal real-world practice in many Azure landing
  zones (Microsoft's own CAF samples vary on this point).

## Consequences

- Validator regex in `02_naming_and_tagging.md` would reject these names
  if applied literally. Either extend the regex with an NSG exception,
  or treat the regex as a guideline for resource types where instance
  counters carry meaning.

## Future work

Extend the naming convention document with an explicit NSG sub-rule:

NSG names: `<org>-<env>-<workload>-<region>-nsg-<subnetName>`