output "argocd_namespace" {
  value       = var.namespace
  description = "Namespace where ArgoCD is installed"
}

output "argocd_release" {
  value       = helm_release.argocd.name
  description = "Helm release name"
}
