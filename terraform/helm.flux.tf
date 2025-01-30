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

resource "helm_release" "flux" {
  depends_on = [kubernetes_secret.flux_git, kubernetes_secret.sops_age]

  name             = "flux"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  namespace        = "flux-system"
  create_namespace = false # created above
  timeout          = 300

  # configure SOPS
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
    name  = "env.SOPS_AGE_KEY_FILE"
    value = "/home/flux/.config/sops/age/age.agekey"
  }

  set {
    name  = "bootstrap.enabled"
    value = "true"
  }

  # set {
  #   name  = "bootstrap.components"
  #   value = "{source-controller,kustomize-controller,helm-controller,notification-controller}"
  # }

  set {
    name  = "bootstrap.gitRepository.create"
    value = "true"
  }

  set {
    name  = "bootstrap.kustomization.create"
    value = "true"
  }

  set {
    name  = "bootstrap.gitRepository.url"
    value = var.flux_repository
  }

  set {
    name  = "bootstrap.gitRepository.ref.branch"
    value = var.flux_branch
  }

  set {
    name  = "bootstrap.gitRepository.secretName"
    value = kubernetes_secret.flux_git.metadata[0].name
  }

  set {
    name  = "bootstrap.kustomization.path"
    value = "./flux/clusters/production"
  }

  set {
    name  = "bootstrap.kustomization.prune"
    value = "true"
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
