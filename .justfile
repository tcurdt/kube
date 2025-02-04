set dotenv-load

watch_repo:
    kubectl --kubeconfig=terraform/.kubeconfig get gitrepositories -A -w

watch_apply:
    kubectl --kubeconfig=terraform/.kubeconfig get kustomizations -A -w

find:
    talosctl --talosconfig terraform/.talosconfig/talosconfig list /usr/lib --nodes 10.0.1.2

k9s:
    k9s --kubeconfig=terraform/.kubeconfig

health:
    talosctl --talosconfig terraform/.talosconfig/talosconfig health

ingress:
    kubectl --kubeconfig=terraform/.kubeconfig get ingress -A
    kubectl --kubeconfig=terraform/.kubeconfig get service -A

    talosctl --talosconfig terraform/.talosconfig/talosconfig get addresses -n 10.0.1.3
    talosctl --talosconfig terraform/.talosconfig/talosconfig netstat -lt -n 10.0.1.3

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

    # talosctl --talosconfig terraform/.talosconfig/talosconfig netstat -tnlp -n 10.0.1.2 -n 10.0.1.3 | grep $IP

    set -x
    curl -I http://$IP:80 || true
    curl -I --insecure --resolve talos.vafer.work:443:$IP https://talos.vafer.work || true
    # openssl s_client -connect $IP:443
    # curl -I --insecure -H "Host: talos.vafer.work" https://$IP:443 || true


reconcile:
    flux --kubeconfig=terraform/.kubeconfig reconcile kustomization flux-system

nodes:
    kubectl --kubeconfig=terraform/.kubeconfig get nodes -o wide
    talosctl --talosconfig terraform/.talosconfig/talosconfig get links --nodes 10.0.1.2
    talosctl --talosconfig terraform/.talosconfig/talosconfig get addresses --nodes 10.0.1.2
    talosctl --talosconfig terraform/.talosconfig/talosconfig get links --nodes 10.0.1.3
    talosctl --talosconfig terraform/.talosconfig/talosconfig get addresses --nodes 10.0.1.3

pods:
    kubectl --kubeconfig=terraform/.kubeconfig get pods -o wide -A --sort-by='{.spec.nodeName}'

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
