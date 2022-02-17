# outputs.tf

# Azure Resource Group
output "Resource-Group" {
  value = azurerm_resource_group.demo-rg.name
}

# Azure inspection-vnet
output "inspection-vnet-Name" {
  value = azurerm_virtual_network.inspection-vnet.name
}
output "inspection-vnet-Address" {
  value = azurerm_virtual_network.inspection-vnet.address_space
}

# Azure Management Subnet
output "Subnet-Management" {
  value = azurerm_subnet.management-subnet.name
}
output "Subnet-Management-Address" {
  value = azurerm_subnet.management-subnet.address_prefixes
}

# Azure Inspection Subnet
output "Subnet-inspection" {
  value = azurerm_subnet.inspection-subnet.name
}
output "Subnet-inspection-Address" {
  value = azurerm_subnet.inspection-subnet.address_prefixes
}

# Azure Sanitized Subnet
output "Subnet-Sanitized-Name" {
  value = azurerm_subnet.sanitized-subnet.name
}
output "Subnet-Sanitized-Address" {
  value = azurerm_subnet.sanitized-subnet.address_prefixes
}

# Azure Load Balancer Subnet
output "Subnet-loadbalancer-Name" {
  value = azurerm_subnet.loadbalancer-subnet.name
}
output "Subnet-loadbalancer-Address" {
  value = azurerm_subnet.loadbalancer-subnet.address_prefixes
}

# Azure Firewall
output "Azure-Firewall" {
  value = azurerm_firewall.azure-firewall.name
}
output "Azure-Firewall-PIP" {
  value = azurerm_public_ip.azure-firewall-PublicIP.ip_address
}

# Log Analytics - Workspace ID and Primary Key
output "Log-Analytics-Workspace-ID" {
  value = azurerm_log_analytics_workspace.log-analytics-workspace.workspace_id
}
output "Log-Analytics-Primary-Key" {
  value     = azurerm_log_analytics_workspace.log-analytics-workspace.primary_shared_key
  sensitive = true
}

# Webserver IP Address
output "Webserver-IP-Address" {
  value = azurerm_linux_virtual_machine.webserver.private_ip_address
}

# Storage Account ID
output "Storage-Account-ID" {
  value = azurerm_storage_account.mystorageaccount.name
}