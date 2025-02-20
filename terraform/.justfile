set dotenv-load

source:
    echo "export KUBECONFIG=$KUBECONFIG"

sops:
    SOPS_AGE_KEY_FILE=.sops.age \
    sops -e .secrets.yaml > secrets.enc.yaml

# download talos image
talos-download:
    wget https://github.com/siderolabs/talos/releases/download/v1.9.3/metal-amd64.raw.zst
    zstd -d metal-amd64.raw.zst
    xz metal-amd64.raw

# upload talos image to hetzner
talos-upload:
    # --image-url "https://github.com/siderolabs/talos/releases/download/v1.9.3/metal-amd64.raw.zst"
    hcloud-upload-image -v upload \
        --server-type cpx21 \
        --image-path metal-amd64.raw.xz \
        --compression xz \
        --labels "talos=v1.9.3,type=cpx21"
images:
    hcloud image list --output columns=id,type,labels

init:
    tofu init

plan:
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu plan -var-file=.env.tfvars

apply:
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu apply -auto-approve -var-file=.env.tfvars

destroy:
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu destroy -var-file=.env.tfvars

top:
    kubectl top pods -A

k9s:
    k9s --kubeconfig .configs/a/kubeconfig

nodes:
    kubectl get nodes -o wide

all:
    kubectl get all -A

crds:
    kubectl get crds -A

ks:
    kubectl get ks -A

secrets:
    kubectl get secrets -A

postgres:
    kubectl cnpg status edkimo -n demo

# kubectl describe node
# kubectl get pods --all-namespaces | grep Pending | awk '{print $2 " -n " $1}' | xargs -L1 kubectl describe pod

talos:
    talosctl --talosconfig .configs/a/talosconfig health --nodes 10.0.1.2

flux:
    kubectl describe pods -n flux-system

watch_repo:
    kubectl get gitrepositories -A -w

watch_apply:
    kubectl get kustomizations -A -w

curl:
    #!/usr/bin/env bash
    IP=$(grep server $KUBECONFIG | sed -e 's/.*https:\/\///' -e 's/:.*$//')

    set -x
    curl -I http://$IP:80 || true
    curl -I --insecure --resolve live.vafer.work:443:$IP https://live.vafer.work || true

    # openssl s_client -connect $IP:443
    # openssl s_client -connect $IP:443 -servername live.vafer.work -no-CAfile
    # curl -I --insecure -H "Host: talos.vafer.work" https://$IP:443 || true
