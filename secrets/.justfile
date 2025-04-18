set quiet := true

# list targets
help:
  @just --list

# encrypt secrets
encrypt:
    SOPS_AGE_KEY_FILE=.sops.age \
    sops -e --input-type=yaml .flux.github.yaml > enc.flux.github.yaml

    SOPS_AGE_KEY_FILE=.sops.age \
    sops -e --input-type=yaml .oci.github.yaml > enc.oci.github.yaml

    SOPS_AGE_KEY_FILE=.sops.age \
    sops -e --input-type=dotenv --output-type=dotenv .env.live > enc.env.live

    SOPS_AGE_KEY_FILE=.sops.age \
    sops -e --input-type=dotenv --output-type=dotenv .env.test > enc.env.test

    SOPS_AGE_KEY_FILE=.sops.age \
    sops -e --encrypted-regex '^(data|stringData)$' .flux.githubapp.yaml > enc.flux.githubapp.yaml

# generate new secrets
rotate:
    # create new secrets
    echo "FOO=secret" > .env.live
    echo "FOO=secret" > .env.test

    # https://fluxcd.io/blog/2025/04/flux-operator-github-app-bootstrap/#github-app-docs
    # client_id: "Iv23linY827U8edj7FEa"

    flux create secret githubapp flux-system \
      --app-id=1219184 \
      --app-installation-id=64688608 \
      --app-private-key=./.edkimo-deployment.2025-04-16.private-key.pem \
      --export > .flux.githubapp.yaml

    kubectl create secret docker-registry oci-github \
    --docker-server=ghcr.io \
    --docker-username=YOUR_USERNAME \
    --docker-password=YOUR_PASSWORD \
    --docker-email=YOUR_EMAIL \
    --dry-run=client \
    -o yaml > .oci.github.yaml

    # encrypt
    just encrypt
