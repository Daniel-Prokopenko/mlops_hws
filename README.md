# goit-argo — HW7 (ArgoCD + Helm MLflow)

## 1) ArgoCD (deployed via Terraform)

ArgoCD was installed into EKS as a Helm release in namespace `infra-tools`.

Terraform commands (run from this repo):

```bash
cd terraform/argocd
terraform init
terraform apply -auto-approve
```

Check:

```bash
kubectl get pods -n infra-tools
kubectl get svc -n infra-tools | grep argocd-server
```

## 2) Open ArgoCD UI (port-forward + login)

Port-forward:

```bash
kubectl -n infra-tools port-forward svc/argocd-server 8080:80
```

Open:

- http://127.0.0.1:8080

Login:

- user: `admin`
- password:

```bash
kubectl -n infra-tools get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

## 3) Deploy MLflow via ArgoCD Application (this repo)

This repo contains:

- `application.yaml` — ArgoCD Application (auto-sync + self-heal + CreateNamespace)
- `values/mlflow-values.yaml` — Helm overrides for MLflow chart

Apply:

```bash
kubectl apply -f application.yaml
```

## 4) Verify GitOps deploy

ArgoCD Application:

```bash
kubectl -n infra-tools get applications mlflow -o wide
```

Kubernetes resources in target namespace `application`:

```bash
kubectl -n application get pods -o wide
kubectl -n application get svc,endpoints -o wide
```

## 5) Open MLflow UI (port-forward)

```bash
kubectl -n application port-forward svc/mlflow 5000:80
```

Open:

- http://127.0.0.1:5000

Health:

```bash
curl http://127.0.0.1:5000/health
```
