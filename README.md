# kairoai-deployments

Helm charts and Kubernetes deployment configuration for KairoAI.

## Purpose

Deploy KairoAI services into AKS using Helm.

## Structure

- `charts/kairoai-service/` - reusable service chart for API and worker services.
- `envs/local/` - local values.
- `envs/dev/` - dev AKS values.
- `envs/staging/` - staging values.
- `envs/prod/` - production values.

## Local Validation

```powershell
helm lint charts/kairoai-service
helm template kairoai-api-gateway charts/kairoai-service -f envs/dev/api-gateway.values.yaml
```
