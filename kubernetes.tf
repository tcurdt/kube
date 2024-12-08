resource "null_resource" "wait_for_cluster" {
  depends_on = [null_resource.talos_bootstrap]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=./kubeconfig

      until kubectl wait --for=condition=ready nodes --all --timeout=600s; do
        echo "Waiting for nodes to be ready..."
        sleep 10
      done

      until kubectl cluster-info; do
        echo "Verifying API server accessibility..."
        sleep 10
      done

      echo "Waiting for core services..."
      kubectl wait --for=condition=ready -n kube-system pod -l k8s-app=kube-dns --timeout=300s

    EOT
  }
}

# resource "kubernetes_namespace" "live" {
#   depends_on = [null_resource.wait_for_cluster]
#   metadata {
#     name = "live"
#     labels = {
#       "managed-by" = "terraform"
#       // "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }
# }

# resource "kubernetes_namespace" "test" {
#   depends_on = [null_resource.wait_for_cluster]
#   metadata {
#     name = "test"
#     labels = {
#       "managed-by" = "terraform"
#       // "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }
# }

# resource "kubernetes_secret" "live_secrets" {
#   depends_on = [kubernetes_namespace.live]

#   metadata {
#     name      = "backend"
#     namespace = kubernetes_namespace.live.metadata[0].name
#     labels = {
#       "managed-by" = "terraform"
#       // "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }

#   data = {
#     "db_password"    = data.sops_file.secrets.data["live.db_password"]
#     "api_key"        = data.sops_file.secrets.data["live.api_key"]
#     "secret_key"     = data.sops_file.secrets.data["live.secret_key"]
#     "admin_password" = data.sops_file.secrets.data["live.admin_password"]
#   }
# }

# resource "helm_release" "flux" {
#   depends_on = [null_resource.wait_for_cluster]

#   name             = "flux"
#   repository       = "https://fluxcd-community.github.io/helm-charts"
#   chart            = "flux2"
#   namespace        = "flux-system"
#   create_namespace = true

#   set {
#     name  = "git.url"
#     value = var.flux_repository
#   }

#   set_sensitive {
#     name  = "git.token"
#     value = data.sops_file.secrets.data["github_token"]
#   }
# }


# resource "helm_release" "ingress_nginx" {
#   depends_on = [null_resource.wait_for_cluster]
#   name       = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "kube-system"
#   timeout    = 300

#   set {
#     name  = "controller.service.type"
#     value = "LoadBalancer"
#   }
#   set {
#     name  = "controller.resources.requests.cpu"
#     value = "50m"
#   }
#   set {
#     name  = "controller.resources.requests.memory"
#     value = "90Mi"
#   }
# }

# resource "helm_release" "cert_manager" {
#   depends_on       = [helm_release.ingress_nginx]
#   name             = "cert-manager"
#   repository       = "https://charts.jetstack.io"
#   chart            = "cert-manager"
#   namespace        = "cert-manager"
#   create_namespace = true
#   timeout          = 300

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }
#   set {
#     name  = "resources.requests.cpu"
#     value = "10m"
#   }
#   set {
#     name  = "resources.requests.memory"
#     value = "32Mi"
#   }
# }

# resource "helm_release" "prometheus_stack" {
#   depends_on       = [helm_release.cert_manager]
#   name             = "prometheus"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "kube-prometheus-stack"
#   namespace        = "monitoring"
#   create_namespace = true
#   timeout          = 300

#   values = [<<-EOT
#       prometheus:
#         resources:
#           requests:
#             cpu: 50m
#             memory: 256Mi
#       grafana:
#         resources:
#           requests:
#             cpu: 50m
#             memory: 128Mi
#       alertmanager:
#         resources:
#           requests:
#             cpu: 10m
#             memory: 32Mi
#       EOT
#   ]

#   set {
#     name  = "grafana.service.type"
#     value = "ClusterIP"
#   }
# }

# resource "helm_release" "example_app" {
#   depends_on = [kubernetes_namespace.apps]
#   name       = "example-app"
#   repository = "https://example.com/charts"
#   chart      = "example"
#   namespace  = kubernetes_namespace.apps.metadata[0].name

#   set_sensitive {
#     name  = "config.dbPassword"
#     value = data.sops_file.secrets.data["db_password"]
#   }
# }
