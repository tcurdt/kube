resource "kubernetes_namespace" "flux" {
  depends_on = [null_resource.wait_for_cluster]

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
    "age.agekey" = file(".sops.age") # SOPS private key
  }
}

resource "kubernetes_secret" "flux_git" {
  depends_on = [kubernetes_namespace.flux]

  metadata {
    name      = "flux-git-auth"
    namespace = "flux-system"
  }

  data = {
    "username" = "git"
    "password" = data.sops_file.secrets.data["flux.github_pat_token"]
  }
}

resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace.flux]

  name       = "flux-operator"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
  wait       = true
}

resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator, kubernetes_secret.flux_git, kubernetes_secret.sops_age]

  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  timeout    = 300

  values = [
    file("config.flux/components.yaml")
  ]

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
    value = var.flux_path
  }

  set {
    name  = "instance.sync.ref"
    value = "refs/heads/${var.flux_branch}"
  }

  set {
    name  = "instance.sync.pullSecret"
    value = kubernetes_secret.flux_git.metadata[0].name
  }
}

output "flux_status" {
  value = {
    namespace = kubernetes_namespace.flux.metadata[0].name
    git_url   = var.flux_repository
    branch    = var.flux_branch
    path      = var.flux_path
  }
}
