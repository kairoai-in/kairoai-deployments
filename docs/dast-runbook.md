# DAST Runbook

KairoAI uses OWASP ZAP from GitHub Actions to scan the deployed public edge.

## Scope

The DAST workflow scans the internet-facing routes that represent the current application attack surface:

- Test dashboard: `https://test.kairoai.in`
- Test API gateway health route: `https://test-api.kairoai.in/health`
- Test Argo CD UI: `https://test-argocd.kairoai.in`
- Production dashboard: `https://kairoai.in`
- Production API gateway health route: `https://api.kairoai.in/health`
- Production Argo CD UI: `https://prod-argocd.kairoai.in`

Production Argo CD scanning should be enabled only after `prod-argocd.kairoai.in` is deployed and DNS is live. Until then, the production DAST workflow is expected to fail at preflight for that target.

## Execution

Run `.github/workflows/dast.yml` manually with:

- `target_environment=test` before promoting Helm changes.
- `target_environment=prod` after production routes are live.
- `zap_scan_mode=baseline` for routine scans.
- `zap_scan_mode=full` for deeper manual validation windows.

The workflow uploads HTML, Markdown, and JSON reports per target.

## Gate

The workflow runs ZAP with warning alerts ignored and fails on ZAP failures. This keeps the gate useful while avoiding noisy warning-only failures during early rollout.

## Notes

Argo CD endpoints should remain protected with strong credentials and should later move behind SSO or conditional access. DAST validates exposure and common web issues, but it does not replace SAST, dependency scanning, IaC scanning, WAF logs, or application authorization tests.
