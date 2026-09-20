# OpenTofu remote state bucket (Phase 2b). Projects migrate with:
#   tofu init -migrate-state
# after S3 API credentials are in 1Password.
#
# R2 does not implement S3 PutBucketVersioning — enable object versioning in the
# Cloudflare dashboard if desired (not available via aws_s3_bucket_versioning).

resource "cloudflare_r2_bucket" "tofu_state" {
  account_id    = data.cloudflare_zone.jacobdrury.account.id
  name          = "homelab-tofu-state"
  location      = "enam"
  storage_class = "Standard"
}
