# Production Values

Production releases use immutable commit tags from `acrkairoaihubci.azurecr.io` and protected deployment approvals.

- Dashboard and API Gateway ingress class: `azure-application-gateway`.
- Front Door terminates public TLS and forwards to Application Gateway WAF.
- Application Gateway forwards HTTP to AKS ClusterIP services through managed AGIC.
- Runtime secret name: `kairoai-runtime-secrets`.
- Review dispatch queue: `review-analysis`.
