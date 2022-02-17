# network.tf

# Resource Group
resource "azurerm_resource_group" "demo-rg" {
  name     = "${var.prefix}-resources"
  location = var.location

  tags = {
    environment = var.demoenv
  }
}

# Create Inspection VNet
resource "azurerm_virtual_network" "inspection-vnet" {
  name                = "inspection-vnet"
  address_space       = ["172.31.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.demo-rg.name

  tags = {
    environment = var.demoenv
  }
}

# Create Hub-Subnets for VMSS NSVA deployment
resource "azurerm_subnet" "management-subnet" {
  name                 = "management-subnet"
  resource_group_name  = azurerm_resource_group.demo-rg.name
  virtual_network_name = azurerm_virtual_network.inspection-vnet.name
  address_prefixes     = ["172.31.0.0/27"]

}
resource "azurerm_subnet" "inspection-subnet" {
  name                 = "inspection-subnet"
  resource_group_name  = azurerm_resource_group.demo-rg.name
  virtual_network_name = azurerm_virtual_network.inspection-vnet.name
  address_prefixes     = ["172.31.0.32/28"]
}
resource "azurerm_subnet" "sanitized-subnet" {
  name                 = "sanitized-subnet"
  resource_group_name  = azurerm_resource_group.demo-rg.name
  virtual_network_name = azurerm_virtual_network.inspection-vnet.name
  address_prefixes     = ["172.31.0.48/28"]
}

resource "azurerm_subnet" "workload-subnet" {
  name                 = "workload-subnet"
  resource_group_name  = azurerm_resource_group.demo-rg.name
  virtual_network_name = azurerm_virtual_network.inspection-vnet.name
  address_prefixes     = ["172.31.0.64/27"]
}

# Load Balancer subnet for VMSS NSVA deployment
resource "azurerm_subnet" "loadbalancer-subnet" {
  name                 = "loadbalancer-subnet"
  resource_group_name  = azurerm_resource_group.demo-rg.name
  virtual_network_name = azurerm_virtual_network.inspection-vnet.name
  address_prefixes     = ["172.31.0.96/27"]
}

# Create Azure Firewall Subnet
resource "azurerm_subnet" "azure-firewall-subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.demo-rg.name
  virtual_network_name = azurerm_virtual_network.inspection-vnet.name
  address_prefixes     = ["172.31.0.128/26"]
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "azure-firewall-PublicIP" {
  name                = "azure-firewall-PublicIP"
  location            = azurerm_resource_group.demo-rg.location
  resource_group_name = azurerm_resource_group.demo-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Firewall
resource "azurerm_firewall" "azure-firewall" {
  name                = "azure-firewall"
  location            = azurerm_resource_group.demo-rg.location
  resource_group_name = azurerm_resource_group.demo-rg.name

  tags = {
    environment = var.demoenv
  }

  ip_configuration {
    name                 = "azure-firewall-PublicIP-configuration"
    subnet_id            = azurerm_subnet.azure-firewall-subnet.id
    public_ip_address_id = azurerm_public_ip.azure-firewall-PublicIP.id
  }
}

# Nat rule collection
resource "azurerm_firewall_nat_rule_collection" "allow-inbound-collection" {
  name = "allow-inbound-collection"
  depends_on = [
    azurerm_public_ip.azure-firewall-PublicIP
  ]
  azure_firewall_name = azurerm_firewall.azure-firewall.name
  resource_group_name = azurerm_resource_group.demo-rg.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "allow-inbound"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "80",
    ]

    destination_addresses = [
      azurerm_public_ip.azure-firewall-PublicIP.ip_address
    ]

    translated_port = 80

    translated_address = "172.31.0.68"

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}

# Network Rule Collection
resource "azurerm_firewall_network_rule_collection" "allow-outbound-collection" {
  name                = "allow-outbound-collection"
  azure_firewall_name = azurerm_firewall.azure-firewall.name
  resource_group_name = azurerm_resource_group.demo-rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "allow-outbound-collection"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "Any",
    ]
  }
}

# Application Rule Collection
resource "azurerm_firewall_application_rule_collection" "application-rule-collection" {
  name                = "application-rule-collection"
  azure_firewall_name = azurerm_firewall.azure-firewall.name
  resource_group_name = azurerm_resource_group.demo-rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "application-rule-collection"

    source_addresses = [
      "172.31.0.68",
    ]

    target_fqdns = [
      "*",
    ]

    protocol {
      port = "80"
      type = "Http"
    }
  }
}

# Route Table Clean to FW
resource "azurerm_route_table" "route-table-sanitized-firewall" {
  name                          = "route-table-sanitized-firewall"
  location                      = azurerm_resource_group.demo-rg.location
  resource_group_name           = azurerm_resource_group.demo-rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "sanitized-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "172.31.0.132"
  }

  tags = {
    environment = var.demoenv
  }
}

# Associate Subnet to route-table-sanitized-firewall
resource "azurerm_subnet_route_table_association" "sanitized-subnet" {
  subnet_id      = azurerm_subnet.sanitized-subnet.id
  route_table_id = azurerm_route_table.route-table-sanitized-firewall.id
}

# Route Table FW to Internet and to Load Balancer
resource "azurerm_route_table" "route-table-internet-loadbalancer" {
  name                          = "route-table-internet-loadbalancer"
  location                      = azurerm_resource_group.demo-rg.location
  resource_group_name           = azurerm_resource_group.demo-rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "firewall-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  route {
    name                   = "firewall-loadbalancer"
    address_prefix         = "172.31.0.64/27"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "172.31.0.100"
  }

  tags = {
    environment = var.demoenv
  }
}

# Associate Subnet to route-table-internet-loadbalancer
resource "azurerm_subnet_route_table_association" "azure-firewall-subnet" {
  subnet_id      = azurerm_subnet.azure-firewall-subnet.id
  route_table_id = azurerm_route_table.route-table-internet-loadbalancer.id
}

# Route Table workload to Load Balancer
resource "azurerm_route_table" "route-table-workload-loadbalancer" {
  name                          = "route-table-workload-loadbalancer"
  location                      = azurerm_resource_group.demo-rg.location
  resource_group_name           = azurerm_resource_group.demo-rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "route-table-workload-loadbalancer-1"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "172.31.0.100"
  }

  route {
    name                   = "route-table-workload-loadbalancer-2"
    address_prefix         = "172.31.0.128/26"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "172.31.0.100"
  }

  tags = {
    environment = var.demoenv
  }
}

# Associate Subnet to route-table-workload-loadbalancer
resource "azurerm_subnet_route_table_association" "workload-subnet" {
  subnet_id      = azurerm_subnet.workload-subnet.id
  route_table_id = azurerm_route_table.route-table-workload-loadbalancer.id
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log-analytics-workspace" {
  name                = "log-analytics-workspace"
  location            = azurerm_resource_group.demo-rg.location
  resource_group_name = azurerm_resource_group.demo-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 60
}