resource "pihole_adlist" "block" {
  for_each = var.block_lists

  address = each.value.address
  type    = "block"
  enabled = each.value.enabled
  comment = each.value.comment
}

resource "pihole_adlist" "allow" {
  for_each = var.allow_lists

  address = each.value.address
  type    = "allow"
  enabled = each.value.enabled
  comment = each.value.comment
}
