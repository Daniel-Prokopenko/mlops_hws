# Terraform: ArgoCD install (EKS + Helm)

## Apply

```bash
# from repo root
cd terraform/argocd

terraform init
terraform apply -auto-approve \
  -var="cluster_name=prk-eks-dev" \
  -var="region=eu-central-1"
```

## Verify

```bash
kubectl get pods -n infra-tools
kubectl get svc -n infra-tools | grep argocd
```

## Open UI

```bash
kubectl -n infra-tools port-forward svc/argocd-server 8080:80
```

Login:

```bash
kubectl -n infra-tools get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
