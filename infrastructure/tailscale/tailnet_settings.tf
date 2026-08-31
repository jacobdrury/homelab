resource "tailscale_tailnet_settings" "homelab" {
  acls_externally_managed_on = true
  acls_external_link         = var.acl_external_link

  # Pin current tailnet values so apply does not reset unrelated admin settings.
  devices_approval_on                         = false
  devices_auto_updates_on                     = true
  devices_key_duration_days                   = 180
  users_approval_on                           = true
  users_role_allowed_to_join_external_tailnet = "admin"
  posture_identity_collection_on              = false
  https_enabled                               = false
}
