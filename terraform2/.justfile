set dotenv-load

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
        --server-type cpx11 \
        --image-path metal-amd64.raw.xz \
        --compression xz \
        --labels "talos=v1.9.3"
images:
    hcloud image list

init:
    tofu init

plan:
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu plan -var-file=.env.tfvars

apply:
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu apply -var-file=.env.tfvars

destroy:
    SOPS_AGE_KEY_FILE=.sops.age \
    tofu destroy -var-file=.env.tfvars

kube:
    kubectl --kubeconfig .configs/a/kubeconfig get all -A

talos:
    talosctl --talosconfig .configs/a/talosconfig health
