# kairoai-deployments

Helm charts and Kubernetes deployment configuration for KairoAI.

## Purpose

Deploy KairoAI services into AKS using Helm.

## Runtime Direction

- Application services deploy with Helm.
- Azure Service Bus is the planned hosted broker for review workers.
proceed - PostgreSQL is not deployed as a pod for hosted environments; services use Azure Database for PostgreSQL Flexible Server from `kairoai-infra`.
- API Gateway handles GitHub `pull_request` webhooks for PR review creation.
- API Gateway handles default-branch GitHub `push` webhooks for repository security baseline refresh.

## Structure

- `charts/kairoai-service/` - reusable service chart for API and worker services.
- `charts/rabbitmq/` - local/legacy compatibility notes only; hosted Azure environments should use Service Bus.
- `envs/local/` - local values.
- `envs/dev/` - dev AKS values.
- `envs/staging/` - staging values.
- `envs/prod/` - production values.

## Local Validation

```powershell
helm lint charts/kairoai-service
helm template kairoai-api-gateway charts/kairoai-service -f envs/dev/api-gateway.values.yaml
helm template kairoai-github-service charts/kairoai-service -f envs/dev/github-service.values.yaml
helm template kairoai-review-orchestrator charts/kairoai-service -f envs/dev/review-orchestrator.values.yaml
helm template kairoai-terraform-runner charts/kairoai-service -f envs/dev/terraform-runner.values.yaml
helm template kairoai-security-service charts/kairoai-service -f envs/dev/security-service.values.yaml
helm template kairoai-cost-service charts/kairoai-service -f envs/dev/cost-service.values.yaml
helm template kairoai-governance-service charts/kairoai-service -f envs/dev/governance-service.values.yaml
helm template kairoai-ai-service charts/kairoai-service -f envs/dev/ai-service.values.yaml
helm template kairoai-review-worker charts/kairoai-service -f envs/dev/review-worker.values.yaml
```

## GitHub App Event Contract

The deployed API Gateway must receive these GitHub App events:

- `pull_request`: creates review jobs and runs the PR analysis flow.
- `push`: refreshes default-branch security baselines when the repository default branch changes.

Keep `GITHUB_WEBHOOK_SECRET` configured in the API Gateway deployment so both event types require `X-Hub-Signature-256` verification.

## Runtime Secrets

Dev AKS values expect a Kubernetes secret named `kairoai-runtime-secrets`.

Use `envs/dev/runtime-secrets.example.env` as the non-secret key list and `scripts/create-dev-runtime-secret.ps1` to create or update the secret for dev validation.

## TLS Direction

Hosted environments should expose public traffic through NGINX Ingress and cert-manager instead of per-service LoadBalancers.

- `kairoai.in` routes to the dashboard.
- `api.kairoai.in` routes to the API Gateway.
- Certificates are requested from the `letsencrypt-prod` ClusterIssuer.
- Dev ClusterIssuer manifest lives at `envs/dev/cluster-issuer.letsencrypt-prod.yaml`.
- GitHub App callback URL should be `https://kairoai.in/api/auth/callback`.
- GitHub webhook URL should be `https://api.kairoai.in/webhooks/github`.

After installing ingress-nginx, point both GoDaddy A records to the ingress controller public IP before waiting for certificates:

```text
kairoai.in      A    <ingress-public-ip>
api.kairoai.in  A    <ingress-public-ip>
```
