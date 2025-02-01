set dotenv-load

sops:
    SOPS_AGE_KEY_FILE=.sops.age \
    sops -e .secrets.yaml > secrets.enc.yaml

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
    touch .kubeconfig
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu plan -var-file=.env.tfvars

apply:
    touch .kubeconfig
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu apply -var-file=.env.tfvars

# check installation
check:
    kubectl --kubeconfig=.kubeconfig get nodes -o wide
    kubectl --kubeconfig=.kubeconfig get all -A
# kubectl --kubeconfig=.kubeconfig get secrets -A
# kubectl --kubeconfig=.kubeconfig get secret backend -n live \
#     -o jsonpath='{.data}' | jq . -r | jq 'map_values(@base64d)'

# check flux locally
flux-local:
    flux --kubeconfig .kubeconfig stats
    flux --kubeconfig .kubeconfig get kustomizations

# check flux status
flux-remote:
    kubectl --kubeconfig=.kubeconfig get gitrepositories -A
    kubectl --kubeconfig=.kubeconfig get kustomizations -A
    kubectl --kubeconfig=.kubeconfig get helmreleases -A
    kubectl --kubeconfig=.kubeconfig get secret flux-git-auth -o yaml
    kubectl --kubeconfig=.kubeconfig -n flux-system describe gitrepository flux-system || true
    kubectl --kubeconfig=.kubeconfig -n flux-system get events
    kubectl --kubeconfig=.kubeconfig -n flux-system get pods
    kubectl --kubeconfig=.kubeconfig -n flux-system get kustomizations

# kubectl --kubeconfig=.kubeconfig -n flux-system logs deploy/source-controller
# kubectl --kubeconfig=.kubeconfig -n flux-system logs service/source-controller
# kubectl --kubeconfig=.kubeconfig -n flux-system logs service/flux-operator

destroy:
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu destroy -var-file=.env.tfvars

init:
    tofu init
