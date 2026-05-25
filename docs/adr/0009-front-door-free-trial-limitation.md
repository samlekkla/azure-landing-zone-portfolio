# ADR 0009 — Front Door Skipped: Azure Free Trial Subscription Block

**Date:** 2026-05-24
**Status:** Accepted

## Context
Azure Front Door Standard was designed as the sole prod ingress per the security 
baseline (04_security_baseline.md) and reference architecture (06_reference_architecture.md).
Deployment was blocked by a hard Azure Free Trial subscription restriction —
Free Trial accounts cannot deploy Azure Front Door resources.

## Decision
Skip Front Door deployment. Document the intended architecture and keep the 
Bicep module (infra/security/modules/front-door.bicep) in the repo as 
"would deploy on a paid subscription."

The WAF policy (nxprodsecswcwafp001) deployed successfully and remains in place.

## What production deployment would add
- Azure Front Door Standard profile: nx-prod-sec-swc-afd-001
- WAF in Prevention mode: DRS 2.1 + Bot Manager 1.0
- Rate limit: 100 req/min per IP on /api/*
- App Service access restriction: AzureFrontDoor.Backend service tag + X-Azure-FDID header
- Estimated cost: ~$35/mo base (deploy-briefly, 7-day demo window)

## Consequence
Prod App Service (nx-prod-web-swc-app-001) is publicly accessible directly.
Mitigated by:
- HTTPS only, TLS 1.2+
- NSG default-deny on snet-app
- Defender for Cloud CSPM monitoring
