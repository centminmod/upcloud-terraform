output "public_ip" {
  value = upcloud_server.server1.network_interface[0].ip_address
}

output "utility_ip" {
  value = upcloud_server.server1.network_interface[1].ip_address
}

output "hostname" {
  value = upcloud_server.server1.hostname
}

output "plan" {
  value = upcloud_server.server1.plan
}

output "zone" {
  value = upcloud_server.server1.zone
}

output "size" {
  value = upcloud_server.server1.template[0].size
}