resource "pihole_domain_list" "this" {
  for_each = var.domains

  domain  = each.value.domain
  type    = each.value.type
  kind    = each.value.kind
  enabled = each.value.enabled
  comment = each.value.comment
}
