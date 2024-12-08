set dotenv-load

sops:
    SOPS_AGE_KEY_FILE=./key.txt \
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

plan:
    SOPS_AGE_KEY_FILE=./key.txt \
    tofu plan -var-file=.env.tfvars

apply:
    SOPS_AGE_KEY_FILE=./key.txt \
    tofu apply -var-file=.env.tfvars

check:
    kubectl --kubeconfig=./kubeconfig get nodes -o wide
    kubectl --kubeconfig=./kubeconfig get pods -A
    kubectl --kubeconfig=./kubeconfig get namespaces
    kubectl --kubeconfig=./kubeconfig get secrets -A
    kubectl --kubeconfig=./kubeconfig get secret backend -n live \
        -o jsonpath='{.data}' | jq . -r | jq 'map_values(@base64d)'
    kubectl --kubeconfig=./kubeconfig describe nodes
    kubectl --kubeconfig=./kubeconfig get all -A

destroy:
    SOPS_AGE_KEY_FILE=./key.txt \
    tofu destroy -var-file=.env.tfvars

init:
    tofu init
