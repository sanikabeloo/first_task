output "resource_group_name" {
  value = azurerm_resource_group.task1_rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.task1_vnet.name
}

output "web_vm_name" {
  value = azurerm_linux_virtual_machine.task1_web_vm.name
}

output "web_public_ip" {
  value = azurerm_public_ip.task1_web_public_ip.ip_address
}

output "web_private_ip" {
  value = azurerm_network_interface.task1_web_nic.private_ip_address
}
