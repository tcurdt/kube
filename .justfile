set dotenv-load

watch_repo:
    kubectl --kubeconfig=terraform/.kubeconfig get gitrepositories -A -w

watch_apply:
    kubectl --kubeconfig=terraform/.kubeconfig get kustomizations -A -w

k9s:
    k9s --kubeconfig=terraform/.kubeconfig

health:
    talosctl --talosconfig terraform/.talosconfig/talosconfig health

ingress:
    kubectl --kubeconfig=terraform/.kubeconfig get ingress -A
    kubectl --kubeconfig=terraform/.kubeconfig get service -A

pull:
    # kubectl --kubeconfig=terraform/.kubeconfig run pull --image=ghcr.io/tcurdt/talos-servicelb:latest --rm -i
    # kubectl --kubeconfig=terraform/.kubeconfig set image daemonset/talos-lb-controller controller=ghcr.io/tcurdt/talos-servicelb:latest -n kube-system
    kubectl --kubeconfig=terraform/.kubeconfig delete pod -n kube-system -l app=talos-lb-controller

images:
    kubectl --kubeconfig=terraform/.kubeconfig get pods -A -o jsonpath='{range .items[*].status.containerStatuses[*]}{.image}{"\t"}{.imageID}{"\n"}{end}' | sort | uniq

lb:
    kubectl --kubeconfig=terraform/.kubeconfig -n kube-system logs daemonset.apps/talos-lb-controller

curl:
    #!/usr/bin/env bash
    IP=$(grep server terraform/.kubeconfig | sed -e 's/.*https:\/\///' -e 's/:.*$//')
    echo $IP
    curl -I http://$IP:30080 || true
    curl -I https://$IP:30443 || true

reconcile:
    flux --kubeconfig=terraform/.kubeconfig reconcile kustomization flux-system

nodes:
    kubectl --kubeconfig=terraform/.kubeconfig get nodes -o wide
    talosctl --talosconfig terraform/.talosconfig/talosconfig get links --nodes 10.0.1.2
    talosctl --talosconfig terraform/.talosconfig/talosconfig get addresses --nodes 10.0.1.2
    talosctl --talosconfig terraform/.talosconfig/talosconfig get links --nodes 10.0.1.3
    talosctl --talosconfig terraform/.talosconfig/talosconfig get addresses --nodes 10.0.1.3

all:
    kubectl --kubeconfig=terraform/.kubeconfig get all -A

secrets:
    kubectl --kubeconfig=terraform/.kubeconfig get secrets -A

# kubectl --kubeconfig=terraform/.kubeconfig get secret backend -n live \
#     -o jsonpath='{.data}' | jq . -r | jq 'map_values(@base64d)'

# # check flux locally
# flux-local:
#     flux --kubeconfig .kubeconfig stats
#     flux --kubeconfig .kubeconfig get kustomizations

flux:
    kubectl --kubeconfig=terraform/.kubeconfig get gitrepositories -A || true
    kubectl --kubeconfig=terraform/.kubeconfig get kustomizations -A || true
    kubectl --kubeconfig=terraform/.kubeconfig get helmreleases -A || true
    kubectl --kubeconfig=terraform/.kubeconfig get secret flux-git-auth -o yaml || true
    kubectl --kubeconfig=terraform/.kubeconfig -n flux-system describe gitrepository flux-system || true
    kubectl --kubeconfig=terraform/.kubeconfig -n flux-system get events || true
    kubectl --kubeconfig=terraform/.kubeconfig -n flux-system get pods || true
    kubectl --kubeconfig=terraform/.kubeconfig -n flux-system get kustomizations || true

# kubectl --kubeconfig=terraform/.kubeconfig -n flux-system logs deploy/source-controller
# kubectl --kubeconfig=terraform/.kubeconfig -n flux-system logs service/source-controller
# kubectl --kubeconfig=terraform/.kubeconfig -n flux-system logs service/flux-operator
