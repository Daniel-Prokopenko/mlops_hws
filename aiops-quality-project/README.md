# aiops-quality-project

Final project scaffold: FastAPI inference + drift сигнал + GitOps (Helm/ArgoCD) + monitoring/logging (Prometheus/Grafana/Loki) + GitLab CI retrain.


## GitLab CI retrain
Pipeline job: `retrain-model` (manual or when `DRIFT_TRIGGERED=true`).

### Variables (CI/CD)
- `CI_REGISTRY_IMAGE`, `CI_REGISTRY_USER`, `CI_REGISTRY_PASSWORD` — GitLab Container Registry (if used).
- `GIT_PUSH_TOKEN` — token with rights to push to repo (required to auto-update Helm values).
- `GIT_PUSH_USER`, `GIT_PUSH_EMAIL` — git identity for CI commits.

Result: CI updates `aiops-quality-project/helm/values.yaml` with new `image.repository` and `image.tag`.
ArgoCD auto-sync will redeploy.
