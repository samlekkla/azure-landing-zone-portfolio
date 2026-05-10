# ADR 0003 — GitHub over Azure DevOps for source and CI/CD

**Status:** Accepted
**Date:** 2026-05-08
**Deciders:** samlekkla

## Context

Project Aurora needs a source control platform and CI/CD pipeline.
Two viable options on Azure:

- **GitHub + GitHub Actions** — Microsoft-owned since 2018, industry default
- **Azure DevOps** — Repos, Pipelines, Boards, Artifacts as a single suite

Both support OIDC federation to Azure, both are free at this project's
scale, both have first-class Bicep support.

## Decision

Use GitHub for source control and GitHub Actions for CI/CD. Document
Azure DevOps as a known alternative.

## Rationale

- **Portfolio visibility.** Recruiters search GitHub by default. Public
  repos are discoverable; ADO repos require invitation.
- **OIDC parity.** Both platforms federate to Azure managed identities
  with no stored secrets. The skill transfers either direction.
- **Free Actions minutes** are unlimited on public repos; ADO caps at
  1,800 minutes/mo on the free tier.
- **Modern Azure shops** increasingly standardise on GitHub. Microsoft's
  own first-party samples (azure-quickstart-templates, AVM modules) live
  on GitHub.

## When Azure DevOps wins

Documented for completeness — would choose ADO if:

- Org already has Boards / Test Plans / Artifacts deeply embedded
- Strict compliance requires regional data residency for source code
- Heavy use of YAML pipeline templates across hundreds of repos with
  shared variable groups
- Long-running self-hosted agents on Azure VNet

## Consequences

- Repo is public; sensitive content must never be committed.
  Mitigated by `.gitignore` and GitHub secret scanning.
- CI minutes are unmetered on public repos.
- Boards / sprint tracking not available without separate tooling.

## Future work

- Enable GitHub Advanced Security on the repo (stretch goal per charter).
- Configure branch protection on `main` requiring PR review and
  passing what-if check.
- Add CODEOWNERS file once contributors are added.