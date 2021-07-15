# output "acebox_ip" {
#   #value = "connect using ssh -i key ${var.acebox_user}@${google_compute_instance.acebox.network_interface[0].access_config[0].nat_ip}"
#   value = {
#     for instance in 
#   }
# }

output "users" {
  value = {
    for index, user in var.users:
    user.email => google_compute_instance.acebox[index].network_interface[0].access_config[0].nat_ip
  }
}

output "acebox_ip" {
  value = "connect using: ssh -i ${path.module}/key ${var.acebox_user}@ip_address"
}

# output "dynatrace_environments" {
#   value = {
#     for env in var.dynatrace_environments: 
#     env.value["env"] => env.value["env"]
#   }
# }

# output "dynatrace_api_tokens" {
#   value = {
#     for env in var.dynatrace_environments: 
#     env.id => env.value["api_token"]
#   }
# }

# output "dynatrace_paas_tokens" {
#   value = {
#     for env in var.dynatrace_environments: 
#     env.id => env.value["paas_token"]
#   }
# }