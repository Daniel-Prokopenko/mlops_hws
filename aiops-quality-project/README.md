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

# Final checks (acceptance)

## API (kubectl port-forward)
If local 8000/8001 is busy, use 8002:
kubectl -n aiops-quality port-forward svc/aiops-quality 8002:8000

Health:
curl -s http://localhost:8002/health

Predict:
curl -s -X POST http://localhost:8002/predict -H "Content-Type: application/json" -d '{"x":5}'

Force drift:
curl -s -X POST http://localhost:8002/predict -H "Content-Type: application/json" -d '{"x":5,"drift":true}'

## Logs (drift visible)
kubectl -n aiops-quality logs deploy/aiops-quality --tail=120

## Loki (stdout collected)
kubectl -n observability port-forward svc/loki 3100:3100

POD=$(kubectl -n aiops-quality get pod -o jsonpath='{.items[0].metadata.name}')
curl -sG "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode "query={pod=\"${POD}\"}" \
  --data-urlencode "start=$(date -u -d '10 minutes ago' +%s)000000000" \
  --data-urlencode "end=$(date -u +%s)000000000" \
  --data-urlencode "limit=50"

## Prometheus (metrics scraped)
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090

curl -s "http://localhost:9090/api/v1/query?query=http_requests_total" | head
curl -s "http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total[5m]))" | head
curl -s "http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,sum by (le)(rate(http_request_latency_seconds_bucket[5m])))" | head
curl -s "http://localhost:9090/api/v1/query?query=drift_detected_total" | head

## Grafana
kubectl -n monitoring port-forward svc/monitoring-grafana 3001:80
Login: admin / (password from monitoring-grafana secret)
Import dashboard: aiops-quality-project/grafana/dashboards.json

## ArgoCD (GitOps)
kubectl -n argocd get applications
kubectl -n aiops-quality get all

## GitLab CI retrain
Run job: retrain-model (manual) or set DRIFT_TRIGGERED=true.
Job retrains model (mock), builds image, updates helm/values.yaml, pushes commit -> ArgoCD auto-sync redeploys.
