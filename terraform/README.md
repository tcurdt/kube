
# github token

https://github.com/settings/tokens

1. GitHub Settings -> Developer Settings -> Personal Access Tokens -> Tokens (classic)
2. Generate new token
    - repo (full control)

Next add the token to the secrets.yaml file.

```
flux:
  github_pat_token: TOKEN
```

Then run `just sops` to encrypt the file.
