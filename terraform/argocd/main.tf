# --- Namespace ---
resource "kubernetes_namespace" "infra_tools" {
  metadata {
    name = var.namespace
  }
}

# --- ArgoCD via Helm ---
resource "helm_release" "argocd" {
  name       = var.release_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  namespace        = kubernetes_namespace.infra_tools.metadata[0].name
  create_namespace = false

  # This makes the chart install CRDs (safe to keep enabled).
  set {
    name  = "crds.install"
    value = "true"
  }

  # Overrides are stored in a separate YAML file as required by HW
  values = [file("${path.module}/values/argocd-values.yaml")]
}
