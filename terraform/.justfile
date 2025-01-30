set dotenv-load

sops:
    SOPS_AGE_KEY_FILE=./.sops.age \
    sops -e secrets.yaml > secrets.enc.yaml

# download talos image
talos-dowload:
    wget https://github.com/siderolabs/talos/releases/download/v1.8.3/metal-amd64.raw.zst
    zstd -d metal-amd64.raw.zst
    xz metal-amd64.raw

# upload talos image to hetzner
talos-upload:
    # --image-url "https://github.com/siderolabs/talos/releases/download/v1.8.3/metal-amd64.raw.zst"
    hcloud-upload-image -v upload \
        --server-type cpx11 \
        --image-path metal-amd64.raw.xz \
        --compression xz \
        --labels "talos=v1.8.3"
images:
    hcloud image list

plan:
    touch kubeconfig
    SOPS_AGE_KEY_FILE=./.sops.age \
    tofu plan -var-file=.env.tfvars

apply:
    touch kubeconfig
    SOPS_AGE_KEY_FILE=./.sops.age \
    tofu apply -var-file=.env.tfvars

# check installation
check:
    kubectl --kubeconfig=./kubeconfig get nodes -o wide
    kubectl --kubeconfig=./kubeconfig get all -A

# check flux status
flux-check:
    kubectl --kubeconfig=./kubeconfig get gitrepositories -A
    kubectl --kubeconfig=./kubeconfig get kustomizations -A
    kubectl --kubeconfig=./kubeconfig get helmreleases -A
    kubectl --kubeconfig=./kubeconfig get events -n flux-system
    kubectl --kubeconfig=./kubeconfig describe gitrepository -n flux-system flux-system || true
    kubectl --kubeconfig=./kubeconfig get pods -n flux-system
    kubectl --kubeconfig=./kubeconfig logs -n flux-system deploy/source-controller
    kubectl --kubeconfig=./kubeconfig get secret -n flux-system flux-git-auth -o yaml

# kubectl --kubeconfig=./kubeconfig describe nodes
# kubectl --kubeconfig=./kubeconfig get pods -A
# kubectl --kubeconfig=./kubeconfig get namespaces
# kubectl --kubeconfig=./kubeconfig get secrets -A
# kubectl --kubeconfig=./kubeconfig get secret backend -n live \
#     -o jsonpath='{.data}' | jq . -r | jq 'map_values(@base64d)'

destroy:
    SOPS_AGE_KEY_FILE=./.sops.age \
    tofu destroy -var-file=.env.tfvars

init:
    tofu init
