# Steady Homelab subnet router is the k8s Connector (prd-homelab-router).
# Interim homelab02 keeps Drury only; drop Homelab advertise on the host when convenient:
#   sudo tailscale set --advertise-routes=192.168.1.0/24
manage_k8s_subnet_router = true
homelab_route_via_k8s    = true
