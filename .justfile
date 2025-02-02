set dotenv-load

watch_repo:
    kubectl --kubeconfig=terraform/.kubeconfig get gitrepositories -A -w

watch_apply:
    kubectl --kubeconfig=terraform/.kubeconfig get kustomizations -A -w

k9s:
    k9s --kubeconfig=terraform/.kubeconfig

talos:
    talosctl --talosconfig terraform/.talosconfig/talosconfig health

curl:
    #!/usr/bin/env bash
    IP=$(grep server terraform/.kubeconfig | sed -e 's/.*https:\/\///' -e 's/:.*$//')
    echo $IP
    curl -I http://$IP:30080 || true
    curl -I https://$IP:30443 || true

delete_caddy:
    kubectl --kubeconfig=terraform/.kubeconfig -n infra delete deployment.apps/caddy
    kubectl --kubeconfig=terraform/.kubeconfig -n infra delete service/caddy
    # kubectl --kubeconfig=terraform/.kubeconfig -n infra delete pod/caddy-68898478df-n6xrh

# trigger:
#     flux --kubeconfig=terraform/.kubeconfig reconcile kustomization flux-system

all:
    kubectl --kubeconfig=terraform/.kubeconfig get nodes -o wide
    kubectl --kubeconfig=terraform/.kubeconfig get all -A

# kubectl --kubeconfig=terraform/.kubeconfig get secrets -A
# kubectl --kubeconfig=terraform/.kubeconfig get secret backend -n live \
#     -o jsonpath='{.data}' | jq . -r | jq 'map_values(@base64d)'

# check flux locally
flux-local:
    flux --kubeconfig .kubeconfig stats
    flux --kubeconfig .kubeconfig get kustomizations

# check flux status
flux-remote:
    kubectl --kubeconfig=terraform/.kubeconfig get gitrepositories -A
    kubectl --kubeconfig=terraform/.kubeconfig get kustomizations -A
    kubectl --kubeconfig=terraform/.kubeconfig get helmreleases -A
    kubectl --kubeconfig=terraform/.kubeconfig get secret flux-git-auth -o yaml
    kubectl --kubeconfig=terraform/.kubeconfig -n flux-system describe gitrepository flux-system || true
    kubectl --kubeconfig=terraform/.kubeconfig -n flux-system get events
    kubectl --kubeconfig=terraform/.kubeconfig -n flux-system get pods
    kubectl --kubeconfig=terraform/.kubeconfig -n flux-system get kustomizations

# kubectl --kubeconfig=terraform/.kubeconfig -n flux-system logs deploy/source-controller
# kubectl --kubeconfig=terraform/.kubeconfig -n flux-system logs service/source-controller
# kubectl --kubeconfig=terraform/.kubeconfig -n flux-system logs service/flux-operator
