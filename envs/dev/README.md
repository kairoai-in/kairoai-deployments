# Dev Environment

Dev values target AKS using Azure Container Registry images from `acrkairoaidev.azurecr.io`.

## Runtime Secret Contract

Create a Kubernetes secret named `kairoai-runtime-secrets` before deploying these charts.

Required keys:

- `github-webhook-secret`
- `github-app-id`
- `github-app-private-key`
- `database-url`
- `celery-broker-url`
- `azure-ai-foundry-endpoint`
- `azure-ai-foundry-api-key`
- `azure-ai-foundry-deployment`
- `azure-ai-foundry-api-version`

In Azure-hosted environments, this secret should be sourced from Azure Key Vault through External Secrets or CSI Secrets Store.

## GitHub App Runtime Contract

The GitHub App webhook URL for dev AKS should point to:

```text
https://api.kairoai.in/api/github/events
```

Required GitHub App event subscriptions:

- `pull_request` for review creation, Terraform validation, Checkov security scanning, annotations, and PR comments.
- `push` for default-branch security baseline refresh.

Default-branch `push` events are handled by API Gateway and forwarded to Review Orchestrator's `POST /baselines/security` endpoint. Non-default-branch pushes are accepted but ignored.

## Active Review Flow Services

Install the active MVP services:

```bash
helm upgrade --install kairoai-api-gateway ../../charts/kairoai-service -f api-gateway.values.yaml
helm upgrade --install kairoai-github-service ../../charts/kairoai-service -f github-service.values.yaml
helm upgrade --install kairoai-review-orchestrator ../../charts/kairoai-service -f review-orchestrator.values.yaml
helm upgrade --install kairoai-terraform-runner ../../charts/kairoai-service -f terraform-runner.values.yaml
helm upgrade --install kairoai-security-service ../../charts/kairoai-service -f security-service.values.yaml
helm upgrade --install kairoai-ai-service ../../charts/kairoai-service -f ai-service.values.yaml
helm upgrade --install kairoai-review-worker ../../charts/kairoai-service -f review-worker.values.yaml
```

The active review flow is:

```text
api-gateway -> review-orchestrator -> github-service
review-worker -> terraform-runner -> security-service -> ai-service -> github-service
api-gateway default-branch push -> review-orchestrator baseline -> security-service
```

## Deployment Readiness Notes

- Use immutable image tags for AKS validation instead of leaving long-lived environments on `dev`.
- Build jobs currently need access to private shared packages. Use GitHub Actions secrets for build-time package access, or move shared contracts to an internal package registry before production hardening.
- Keep `GITHUB_WEBHOOK_SECRET`, `GITHUB_APP_ID`, and `GITHUB_APP_PRIVATE_KEY` sourced from Key Vault-backed Kubernetes secrets.
- Baseline refresh requires API Gateway, Review Orchestrator, Security Service, PostgreSQL, and GitHub App credentials to be available.

## Service Image Publishing Secrets

Each active service repository should define these GitHub Actions secrets before relying on automatic image publishing:

- `ACR_LOGIN_SERVER`
- `ACR_USERNAME`
- `ACR_PASSWORD`
- `KAIROAI_PACKAGE_READ_TOKEN` if private cross-repository package installs need more access than the default `GITHUB_TOKEN`.

The service workflows publish both immutable `${GITHUB_SHA}` tags and a moving `dev` tag to ACR on pushes to `main`.

Current dev ACR:

- Registry: `acrkairoaidev.azurecr.io`
- Resource group: `rg-kairoai-dev`
- SKU: `Basic`
- Admin user: disabled
- CI push identity: service principal with `AcrPush` scoped to the registry
