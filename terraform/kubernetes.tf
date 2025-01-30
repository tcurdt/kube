resource "null_resource" "wait_for_cluster" {
  depends_on = [null_resource.talos_bootstrap]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=.kubeconfig

      until kubectl wait --for=condition=ready nodes --all --timeout=600s; do
        echo "waiting for nodes..."
        sleep 10
      done
      echo "nodes are ready"

      until kubectl cluster-info; do
        echo "waiting for kubernetes..."
        sleep 10
      done
      echo "kubernetes is ready"

      echo "waiting for core services..."
      kubectl wait --for=condition=ready -n kube-system pod -l k8s-app=kube-dns --timeout=300s
      echo "core services are ready"

    EOT
  }
}
