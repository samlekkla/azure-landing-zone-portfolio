# ADR 0010 — Azure OpenAI Model Deployments Blocked on Free Trial

**Date:** 2026-05-24
**Status:** Accepted

## Context
Azure OpenAI account (nx-prod-ai-swc-oai-001) deployed successfully but model 
deployments (gpt-4o-mini, text-embedding-3-small) failed with quota limit 0 on 
both GlobalStandard and Standard tiers. This is a hard Free Trial subscription 
block, not a configuration issue.

## Decision
Keep the OpenAI account and Bicep module in the repo. Document the intended 
architecture. Model deployments will succeed on a Pay-As-You-Go subscription.

## What production deployment would add
- gpt-4o-mini: GlobalStandard, 10K TPM — Trail Buddy chat responses
- text-embedding-3-small: GlobalStandard, 10K TPM — product catalog embeddings
- Estimated cost: ~$0.15/M input tokens + $0.60/M output tokens (negligible at demo scale)
- Budget cap: $5 max for the project

## Trail Buddy in this portfolio
- AI Search index and catalog document upload: completed
- RAG service code (app/api/src/services/trailBuddy.js): written and committed
- Wire-up: blocked pending model deployment quota
- Architecture diagram shows the full RAG pattern

## Consequence
Trail Buddy chat endpoint returns placeholder response on Free Trial.
All surrounding infrastructure (Search index, Storage, managed identity 
role assignments) is production-ready and demonstrates the RAG pattern.
