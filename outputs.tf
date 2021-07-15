# output "acebox_ip" {
#   #value = "connect using ssh -i key ${var.acebox_user}@${google_compute_instance.acebox.network_interface[0].access_config[0].nat_ip}"
#   value = {
#     for instance in 
#   }
# }
output "instances" {
  value = {
    for instance in google_compute_instance.acebox: 
    instance.id => instance.network_interface[0].access_config[0].nat_ip
  }
}

output "users" {
  value = {
    for index, user in var.users:
    user.email => google_compute_instance.acebox[index].network_interface[0].access_config[0].nat_ip
  }
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