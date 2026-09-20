# Remote state on Cloudflare R2 (S3-compatible). Credentials: AWS_ACCESS_KEY_ID /
# AWS_SECRET_ACCESS_KEY from moon.yml → 1Password "Homelab R2 tofu state".
terraform {
  backend "s3" {
    bucket = "homelab-tofu-state"
    key    = "cloudflare/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://ae322c0377392a008d6af780a890af30.r2.cloudflarestorage.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
  }
}
