# ADR 0002 — Conditional Access via Security Defaults

**Status:** Accepted
**Date:** 2026-05-08
**Deciders:** <your-handle>

## Context

`04_security_baseline.md` requires Conditional Access policies (block
legacy auth, MFA on all users, geo-restriction). Full Conditional
Access requires Microsoft Entra ID P1 ($6/user/mo).

## Decision

Use Microsoft Entra Security Defaults for the project window.
Document P1 design as future work.

## Rationale

- Free tier covers MFA enforcement and legacy-auth blocking — the two
  highest-impact controls.
- Geo-restriction and per-app policies require P1 — documented for
  the architect deliverable, not deployed.
- Break-glass account has MFA enabled (FIDO2 / Authenticator backup
  codes stored offline) per Microsoft guidance — Security Defaults
  cannot exempt accounts.

## Consequences

- Cannot exempt break-glass from MFA — mitigated by offline backup codes.
- No country-based blocking until P1 trial enabled.
- 30-day P1 trial available for the demo presentation.

## Future work

Enable P1 trial in Week 4 for the demo. Build CA policies:
- Block sign-in from countries outside Sweden + EU
- Require compliant device for admin roles
- Sign-in risk-based MFA prompts