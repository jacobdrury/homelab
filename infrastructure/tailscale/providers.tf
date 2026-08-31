# Auth via env (injected by moon + 1Password):
#   TAILSCALE_OAUTH_CLIENT_ID / TAILSCALE_OAUTH_CLIENT_SECRET  (preferred)
#   TAILSCALE_TAILNET  — use "-" for the credential's default tailnet
provider "tailscale" {}
