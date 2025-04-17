resource "kubernetes_namespace" "flux" {
  depends_on = [kubernetes_config_map.cluster_ready]
  # depends_on = [talos_cluster_kubeconfig.this]
  metadata {
    name = "flux-system"
  }
}

resource "kubernetes_secret" "sops_age" {
  depends_on = [kubernetes_namespace.flux]
  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }
  data = {
    "age.agekey" = file("../../secrets/.sops.age") # SOPS private key
  }
}

# github
data "sops_file" "secrets" {
  source_file = "../../secrets/enc.flux.github.yaml"
}
resource "kubernetes_secret" "flux_github" {
  depends_on = [kubernetes_namespace.flux]
  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }
  data = {
    "username" = "git"
    "password" = data.sops_file.secrets.data["flux.github.fine_pat_token"]
  }
}

# github app
# data "sops_file" "secrets" {
#   source_file = "../../secrets/enc.flux.githubapp.yaml"
# }
# resource "kubernetes_secret" "flux_github" {
#   depends_on = [kubernetes_namespace.flux]
#   metadata {
#     name      = "flux-system"
#     namespace = "flux-system"
#   }
#   data = {
#     "githubAppID"             = data.sops_file.secrets.data["stringData.githubAppID"]
#     "githubAppInstallationID" = data.sops_file.secrets.data["stringData.githubAppInstallationID"]
#     "githubAppPrivateKey"     = data.sops_file.secrets.data["stringData.githubAppPrivateKey"]
#   }
# }


resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace.flux]
  name       = "flux-operator"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
  wait       = true
}

# resource "helm_release" "external_secrets" {
#   depends_on = [kubernetes_namespace.flux]
#   name       = "external-secrets"
#   namespace  = "flux-system"
#   repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
#   chart      = "external-secrets"
#   wait       = true
# }

resource "helm_release" "flux_instance" {
  depends_on = [
    # helm_release.external_secrets,
    helm_release.flux_operator,
    kubernetes_secret.flux_github,
    kubernetes_secret.sops_age
  ]
  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  timeout    = 300
  values     = [file("${path.module}/flux.components.yaml")]

  # sops

  set {
    name  = "instance.env[0].name"
    value = "SOPS_AGE_KEY_FILE"
  }

  set {
    name  = "instance.env[0].value"
    value = "/home/flux/.config/sops/age/age.agekey"
  }

  # flux

  set {
    name  = "instance.distribution.registry"
    value = "ghcr.io/fluxcd"
  }

  set {
    name  = "instance.distribution.version"
    value = "2.x"
  }

  # git

  set {
    name  = "instance.sync.kind"
    value = "GitRepository"
  }

  set {
    name  = "instance.sync.url"
    value = var.flux_repository
  }

  set {
    name  = "instance.sync.path"
    value = "./flux/clusters/${var.cluster_name}/kustomizations"
  }

  set {
    name  = "instance.sync.ref"
    value = "refs/heads/${var.flux_branch}"
  }

  # set {
  #   name  = "instance.sync.provider"
  #   value = "github" // "generic"
  # }

  set {
    name  = "instance.sync.pullSecret"
    value = kubernetes_secret.flux_github.metadata[0].name
  }
}

output "flux_status" {
  value = {
    namespace = kubernetes_namespace.flux.metadata[0].name
    git_url   = var.flux_repository
    branch    = var.flux_branch
    path      = "./flux/clusters/${var.cluster_name}/kustomizations"
  }
}
