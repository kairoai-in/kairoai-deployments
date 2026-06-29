# Test Argo CD

Test uses the Azure Argo CD preview extension. Public access follows `test-argocd.kairoai.in -> Azure Front Door -> test Application Gateway WAF -> AGIC -> argocd-server`; never expose `argocd-server` with a public `LoadBalancer`.

Apply `ingress/test-argocd.yaml` only after the extension and `argocd-server` service are healthy. Production already has Argo CD application manifests, so do not enable a second production controller without a controlled migration.
