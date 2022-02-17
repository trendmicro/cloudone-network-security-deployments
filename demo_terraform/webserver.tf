# webserver.tf

# Create public IP
/* resource "azurerm_public_ip" "pubip" {
  name                = "myPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo-rg.name
  allocation_method   = "Static"
} */

resource "azurerm_network_interface" "webserver-nic" {
  name                = "webserver-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo-rg.name

  ip_configuration {
    name                          = "vm-ip-config"
    subnet_id                     = azurerm_subnet.workload-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.demoenv
  }
}

/* resource "azurerm_marketplace_agreement" "apacheplan-1" {
  publisher = "cognosys"
  offer     = "apache-web-server-with-centos-77-free"
  plan      = "hourly"
} */

# Create Web Server
resource "azurerm_linux_virtual_machine" "webserver" {
  name                            = "webserver"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.demo-rg.name
  network_interface_ids           = [azurerm_network_interface.webserver-nic.id]
  disable_password_authentication = false
  size                            = "Standard_D2s_v4"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  /*   user_data                       = <<EOF
  #! /bin/bash
  sudo apt-get update
  sudo apt-get install -y apache2
  sudo systemctl start apache2
  sudo systemctl enable apache2
  echo "<h1>Demo Apache Web Server</h1>" | sudo tee /var/www/html/index.html
  EOF */

  plan {
    publisher = "cognosys"
    product   = "apache-web-server-with-centos-77-free"
    name      = "apache-web-server-with-centos-77-free"
  }

  provisioner "local-exec" {
    command = "az vm image terms accept --urn cognosys:apache-web-server-with-centos-77-free:apache-web-server-with-centos-77-free:1.2019.1009"
  }

  # Run this command in the Subscription that the Webserver will be deplyed from the Azure Cloud Shell
  # az vm image terms accept --urn cognosys:apache-web-server-with-centos-77-free:apache-web-server-with-centos-77-free:1.2019.1009

  source_image_reference {
    /*  publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest" */
    publisher = "cognosys"
    offer     = "apache-web-server-with-centos-77-free"
    sku       = "apache-web-server-with-centos-77-free"
    version   = "1.2019.1009"
  }

  os_disk {
    name                 = "webserver-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  /*  # Copies the azure-user-data.sh file to /var/tmp/
    provisioner "file" {
    source      = "./azure-user-data.sh"
    destination = "/var/tmp/"
  } */

  tags = {
    environment = var.demoenv
  }
}

# Create Network security group
resource "azurerm_network_security_group" "vm-sg" {
  name                = "${var.prefix}-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.demo-rg.name

  security_rule {
    name                       = "All"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "70.121.85.105/32"
    destination_address_prefix = "*"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "vm1_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.webserver-nic.id
  network_security_group_id = azurerm_network_security_group.vm-sg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${var.prefix}-sg"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.demo-rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.demoenv
  }
}