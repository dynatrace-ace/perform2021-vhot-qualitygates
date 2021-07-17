output "dashboard_url" {
  value = {
    for index, user in var.users:
    user.email => "http://dashboard.${google_compute_instance.acebox[index].network_interface[0].access_config[0].nat_ip}.nip.io"
  }
}

output "acebox_ip" {
  value = "connect using: ssh -i ${path.module}/key ${var.acebox_user}@ip_address"
}
