# Renovate

**Status:** Mend Renovate GitHub App (Renovate Only — free). No in-cluster deploy.

Config: [`renovate.json`](../../renovate.json) at repo root.

## Why this path

| Choice | Role |
|--------|------|
| **Mend Renovate Only** | Hosted bot; opens version/digest PRs for Helm charts, images, Actions, proto tools |
| **Not** Mend Application Security | Paid AppSec suite — skip |
| **Not** in-cluster CronJob | Renovate only needs GitHub; no cluster/Homepage/Kuma |
| **Dependabot** | Security updates OK; **do not** enable Dependabot version updates (fights Renovate) |

## One-time setup

1. Install [Mend Renovate](https://github.com/apps/renovate) (product: **Renovate Only**).
2. Org installed on **all repos** → Mend defaults to **Scan Only / silent** (no PRs). In the Mend Developer Platform, set **this repo** to interactive / **Scan and Alert**.
3. Merge `renovate.json` on `main` (this repo) — skips interactive onboarding.

## What it updates

- Argo CD Applications — Helm `targetRevision` under `clusters/**/application.yaml` (`main` git refs ignored)
- Container images — `image: …:tag@sha256:…` in cluster manifests + `image.tag` in Helm values
- GitHub Actions — `.github/workflows/*`
- proto — built-ins via native manager (`moon`, `rust`); plugin tools via `# renovate:` comments in [`.prototools`](../../.prototools)

## Ops notes

- Schedule: anytime (no `schedule:` preset — Renovate’s default).
- Dependency Dashboard issue lists pending updates.
- Digests are grouped; major platform charts stay as separate PRs for review.
- After the first wave of PRs, tighten `packageRules` if anything is noisy.
