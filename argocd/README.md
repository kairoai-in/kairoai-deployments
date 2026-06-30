# KairoAI ArgoCD

This directory contains ArgoCD application definitions and platform exposure manifests.

## Test Preview Exposure

- Test uses the Azure Argo CD preview extension in AKS before we touch production.
- Public access stays on the approved edge path: `test-argocd.kairoai.in -> Azure Front Door -> test Application Gateway WAF -> AGIC -> argocd-server`.
- Do not expose `argocd-server` with a public `LoadBalancer`.
- Apply the test ingress only after the extension is healthy and the `argocd-server` service exists.
- Test Argo CD applications live under `argocd/test`. They target the `test` branch and are intentionally manual-sync first so we can verify values/secrets before Argo takes over live deployment.

```powershell
az aks command invoke `
  --resource-group rg-kairoai-test-ci `
  --name aks-kairoai-test-ci `
  --subscription 6b01db76-626a-44a2-8119-17682410914a `
  --file . `
  --command "kubectl apply -f argocd/ingress/test-argocd.yaml"
```

Bootstrap the test applications after the `test` branch contains the same manifests:

```powershell
az aks command invoke `
  --resource-group rg-kairoai-test-ci `
  --name aks-kairoai-test-ci `
  --subscription 6b01db76-626a-44a2-8119-17682410914a `
  --file . `
  --command "kubectl apply -n argocd -f argocd/test/project.yaml; kubectl apply -n argocd -f argocd/test/apps"
```

Production keeps its existing Helm-managed Argo CD controller. Do not enable the Azure preview extension in prod without a controlled migration because that would create a second controller for the same applications.

Expose the existing production controller through the approved edge path:

`prod-argocd.kairoai.in -> Azure Front Door -> production Application Gateway WAF -> AGIC -> argocd-server`

Because TLS terminates at Azure Front Door/Application Gateway, the backend Argo CD server must run in insecure HTTP mode. Otherwise Argo CD redirects HTTP back to HTTPS and the public URL loops forever.

```powershell
az aks command invoke `
  --resource-group rg-kairoai-prod-ci `
  --name aks-kairoai-prod-ci `
  --subscription a8270be7-dabc-4d92-98db-26a55025b0df `
  --file . `
  --command "kubectl apply -f argocd/config/prod-cmd-params.yaml; kubectl rollout restart deployment/argocd-server -n argocd"
```

```powershell
az aks command invoke `
  --resource-group rg-kairoai-prod-ci `
  --name aks-kairoai-prod-ci `
  --subscription a8270be7-dabc-4d92-98db-26a55025b0df `
  --file . `
  --command "kubectl apply -f argocd/ingress/prod-argocd.yaml"
```

If the ApplicationSet controller reports that `applicationsets.argoproj.io` is missing, install the CRD matching the deployed Argo CD version. Server-side apply avoids the Kubernetes client-side annotation size limit:

```powershell
az aks command invoke `
  --resource-group rg-kairoai-prod-ci `
  --name aks-kairoai-prod-ci `
  --subscription a8270be7-dabc-4d92-98db-26a55025b0df `
  --command "kubectl apply --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.4.4/manifests/crds/applicationset-crd.yaml"
```

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
