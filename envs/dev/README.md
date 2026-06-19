# Dev Environment

Dev values target AKS using Azure Container Registry images.

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
```
