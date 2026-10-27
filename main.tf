
#rg
resource "azurerm_resource_group" "task1_rg" {
  name     = "task1-rg"
  location = var.location
}

#vnet
resource "azurerm_virtual_network" "task1_vnet" {
  name                = "task1-vnet"
  location            = azurerm_resource_group.task1_rg.location
  resource_group_name = azurerm_resource_group.task1_rg.name
  address_space       = ["10.0.0.0/16"]
}

#websubnet
resource "azurerm_subnet" "task1_web_subnet" {
  name                 = "task1-web-subnet"
  resource_group_name  = azurerm_resource_group.task1_rg.name
  virtual_network_name = azurerm_virtual_network.task1_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


#appsubnet
resource "azurerm_subnet" "task1_app_subnet" {
  name                 = "task1-app-subnet"
  resource_group_name  = azurerm_resource_group.task1_rg.name
  virtual_network_name = azurerm_virtual_network.task1_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

#dbsubnet
resource "azurerm_subnet" "task1_db_subnet" {
  name                 = "task1-db-subnet"
  resource_group_name  = azurerm_resource_group.task1_rg.name
  virtual_network_name = azurerm_virtual_network.task1_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

#bastion subnet - mandatory to add bastion subnet name as AzureBastionSubnet
resource "azurerm_subnet" "task1_bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.task1_rg.name
  virtual_network_name = azurerm_virtual_network.task1_vnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

#nsg for web
resource "azurerm_network_security_group" "task1_web_nsg" {
  name                = "task1-web-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.task1_rg.name
}

resource "azurerm_network_security_rule" "task1_allow_http" {
  name                        = "task1-allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.task1_rg.name
  network_security_group_name = azurerm_network_security_group.task1_web_nsg.name
}

resource "azurerm_network_security_rule" "task1_allow_ssh" {
  name                        = "task1-allow-ssh"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.task1_rg.name
  network_security_group_name = azurerm_network_security_group.task1_web_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "task1_web_nsg_association" {
  subnet_id                 = azurerm_subnet.task1_web_subnet.id
  network_security_group_id = azurerm_network_security_group.task1_web_nsg.id
}

#appnsg
resource "azurerm_network_security_group" "task1_app_nsg" {
  name                = "task1-app-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.task1_rg.name
}

resource "azurerm_subnet_network_security_group_association" "task1_app_nsg_association" {
  subnet_id                 = azurerm_subnet.task1_app_subnet.id
  network_security_group_id = azurerm_network_security_group.task1_app_nsg.id
}

#dbnsg
resource "azurerm_network_security_group" "task1_db_nsg" {
  name                = "task1-db-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.task1_rg.name
}

resource "azurerm_subnet_network_security_group_association" "task1_db_nsg_association" {
  subnet_id                 = azurerm_subnet.task1_db_subnet.id
  network_security_group_id = azurerm_network_security_group.task1_db_nsg.id
}


#publicip
resource "azurerm_public_ip" "task1_web_public_ip" {
  name                = "task1-web-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.task1_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

#netinterface
resource "azurerm_network_interface" "task1_web_nic" {
  name                = "task1-web-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.task1_rg.name

  ip_configuration {
    name                          = "task1-ip-config"
    subnet_id                     = azurerm_subnet.task1_web_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.task1_web_public_ip.id
  }
}
#VM
resource "azurerm_linux_virtual_machine" "task1_web_vm" {
  name                = "task1-web-vm-1"
  resource_group_name = azurerm_resource_group.task1_rg.name
  location            = var.location
  size                = "Standard_B2ats_v2"

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.task1_web_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    name                 = "task1-web-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF
  )
}
