output "vm1_public_ip" {
  value = azurerm_public_ip.vm1_ip.ip_address
}

output "vm2_private_ip" {
  value = azurerm_network_interface.nic_vm2.ip_configuration[0].private_ip_address
}

