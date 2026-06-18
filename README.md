# kairoai-deployments

Helm charts and Kubernetes deployment configuration for KairoAI.

## Purpose

Deploy KairoAI services into AKS using Helm.

## Runtime Direction

- Application services deploy with Helm.
- RabbitMQ is the planned broker for Celery workers.
- PostgreSQL is not deployed as a pod for hosted environments; services use Azure Database for PostgreSQL Flexible Server from `kairoai-infra`.

## Structure

- `charts/kairoai-service/` - reusable service chart for API and worker services.
- `charts/rabbitmq/` - placeholder for RabbitMQ deployment values or dependency configuration.
- `envs/local/` - local values.
- `envs/dev/` - dev AKS values.
- `envs/staging/` - staging values.
- `envs/prod/` - production values.

## Local Validation

```powershell
helm lint charts/kairoai-service
helm template kairoai-api-gateway charts/kairoai-service -f envs/dev/api-gateway.values.yaml
```
