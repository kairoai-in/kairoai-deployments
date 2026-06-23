# Production Values

Production releases use immutable commit tags from `acrkairoaihubci.azurecr.io` and protected deployment approvals.

- Dashboard and API Gateway ingress class: `azure-application-gateway`.
- Front Door terminates public TLS and forwards to Application Gateway WAF.
- Application Gateway forwards HTTP to AKS ClusterIP services through managed AGIC.
- Runtime secret name: `kairoai-runtime-secrets`.
- `kairoai-runtime-secrets` is synchronized from `kv-kairoai-prod-ci` by the Azure Key Vault CSI driver; values never belong in Helm files.
- Review dispatch queue: `review-analysis`.
