resource "null_resource" "wait_for_cluster" {
  depends_on = [null_resource.talos_bootstrap]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=.kubeconfig

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
