# ADR 0008 — CI/CD Identity Model: Per-Environment User-Assigned Managed Identities

**Date:** 2026-05-21
**Status:** Accepted

## Context
GitHub Actions pipeline needs credentials to deploy Azure resources.

## Decision
Two user-assigned MIs — one per environment:
- `nx-dev-gov-swc-mi-001` in `nx-dev-gov-rg`
- `nx-prod-gov-swc-mi-001` in `nx-prod-gov-rg`

Federated credentials locked to: repository + ref:refs/heads/main + GitHub Environment (dev/prod).
Each MI: Contributor + User Access Administrator at workload RG scope only.

## Rejected alternatives
- **Shared MI**: compromised dev pipeline could deploy to prod.
- **Service principal with secret**: violates security baseline rule 4 — no stored secrets.
- **Owner at subscription**: violates security baseline — no subscription-scope Owner on MIs.

## Consequences
Bootstrap (creating MIs + role assignments) runs manually once from local machine.
All subsequent deployments run through the pipeline.
