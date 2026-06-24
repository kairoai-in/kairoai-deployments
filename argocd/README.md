# KairoAI ArgoCD

This directory contains ArgoCD application definitions for the production AKS deployment.

## Production Sync Model

- ArgoCD watches the `prod` branch of `kairoai-in/kairoai-deployments`.
- Each KairoAI service is an ArgoCD `Application`.
- Applications render `charts/kairoai-service` with the matching `envs/prod/*.values.yaml`.
- Runtime secrets render `charts/kairoai-runtime-secrets` with `envs/prod/runtime-secrets.values.yaml`.
- Production image promotion happens through service release workflows, which update the `prod` branch values files.

## Apply

```powershell
az aks command invoke `
  --resource-group rg-kairoai-prod-ci `
  --name aks-kairoai-prod-ci `
  --file . `
  --command "kubectl apply -n argocd -f argocd/project.yaml; kubectl apply -n argocd -f argocd/apps"
```

## AGIC Ingress Health

Azure Application Gateway Ingress Controller can leave `status.loadBalancer` empty even when routing is healthy through Application Gateway/Front Door.
The production cluster patches `argocd-cm` with an Ingress health customization so AGIC-managed ingress apps do not remain `Progressing` forever.

