resource "kubernetes_namespace" "flux_system" {
  depends_on = [null_resource.wait_for_cluster]

  metadata {
    name = "flux-system"
  }
}

# Create secret with SOPS Age key
resource "kubernetes_secret" "sops_age" {
  depends_on = [kubernetes_namespace.flux_system]

  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }

  data = {
    "age.agekey" = file("./key.txt")  # Your SOPS Age private key
  }
}

# Create Git authentication secret
resource "kubernetes_secret" "flux_git" {
  depends_on = [kubernetes_namespace.flux_system]

  metadata {
    name      = "flux-git-auth"
    namespace = "flux-system"
  }

  data = {
    "username" = "git"
    "password" = data.sops_file.secrets.data["github_token"]
  }
}

# Install Flux
resource "helm_release" "flux" {
  depends_on = [kubernetes_secret.flux_git, kubernetes_secret.sops_age]

  name             = "flux"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  namespace        = "flux-system"
  create_namespace = false  # We created it above
  timeout          = 300

  set {
    name  = "git.url"
    value = var.flux_repository
  }

  set {
    name  = "git.secretName"
    value = kubernetes_secret.flux_git.metadata[0].name
  }

  # Configure SOPS
  set {
    name  = "extraSecretMounts[0].name"
    value = "sops-age"
  }

  set {
    name  = "extraSecretMounts[0].secretName"
    value = kubernetes_secret.sops_age.metadata[0].name
  }

  set {
    name  = "extraSecretMounts[0].mountPath"
    value = "/home/flux/.config/sops/age"
  }

  set {
    name  = "env[0].name"
    value = "SOPS_AGE_KEY_FILE"
  }

  set {
    name  = "env[0].value"
    value = "/home/flux/.config/sops/age/age.agekey"
  }
}

output "flux_status" {
  value = {
    namespace = kubernetes_namespace.flux_system.metadata[0].name
    git_url   = helm_release.flux.values[0].git_url
  }
} 