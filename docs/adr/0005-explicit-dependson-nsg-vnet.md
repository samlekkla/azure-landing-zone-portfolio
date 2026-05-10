# ADR 0005 — Explicit dependsOn for NSG→VNet attachment

**Status:** Accepted
**Date:** 2026-05-09
**Deciders:** <your-handle>

## Context

`05_iac_standards.md` lists explicit `dependsOn` as an anti-pattern.
Bicep usually infers dependencies from resource references.

The network deployment needs NSG IDs to attach to subnets at VNet
creation time. Reading NSG module outputs inside a `var` block fails
with BCP182 — `var` is evaluated at deployment start, before module
outputs exist.

## Decision

Construct NSG resource IDs synthetically with `resourceId()` based on
the known naming convention, and add explicit `dependsOn: [hubNsgs]`
(etc.) on each VNet module to enforce ordering.

## Rationale

- The naming convention is stable and enforced by Azure Policy, so
  the synthetic ID will match the real resource ID.
- Without `dependsOn`, Bicep would deploy VNets and NSGs in parallel.
  The VNet might reference an NSG ID that doesn't yet exist.
- The trade-off is one anti-pattern exception in exchange for the
  module reuse pattern across hub + 2 spokes.

## Consequences

- Renaming an NSG silently breaks the link — the synthetic ID won't
  match. Mitigated by the naming validator skill.
- New contributors must read this ADR before refactoring.

## Future work

Watch for Bicep language updates (deploymentStack-style outputs in
var) that would allow the cleaner approach.