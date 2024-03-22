resource "azurerm_resource_group" "vm-linux" {
  location = var.resource_group_location
  name     = var.prefix
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm-linux.location
  resource_group_name = azurerm_resource_group.vm-linux.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.vm-linux.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${var.prefix}-public-ip"
  location            = azurerm_resource_group.vm-linux.location
  resource_group_name = azurerm_resource_group.vm-linux.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.vm-linux.location
  resource_group_name = azurerm_resource_group.vm-linux.name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.vm-linux.location
  resource_group_name = azurerm_resource_group.vm-linux.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Create VM linux
resource "azurerm_linux_virtual_machine" "vm-linux" {
  name                = "vm-linux"
  resource_group_name = azurerm_resource_group.vm-linux.name
  location            = azurerm_resource_group.vm-linux.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.my_terraform_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

# Add the admin SSH key block
  admin_ssh_key {
    username = "adminuser" # Make sure this matches your admin username
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwrO7pZQaaBl+p2W2JK5RqsZbD5Ep7sEh2uV52F2QJxcvKAbQ11jiyPTypzN7S19ZLwmbvp5lDSKA6aRXxa00Yp7R4N4uO/tCzp+Mf/SGtrreS6DIs/iGv/uChJTpMkcoD0vnwXPv/lChv1Mx4jCW2oQZfcBjU+Dr0u5C1eC2xGnrSPcLWM8DGKBpbWJgY1eSXR0+jPiaQIm/GqyuBzaHfjeecNSsTSPWk/1qVLerhGxZnM03F8FvQMh1Ayt4CctUeCgTxOgYVxq1AXNN7euD3aVQwizBPrRqdSOPP9DCkckUE7VPbJV1xMktffgaLiRR8ZFcZvrkN0oWWQHhbh1AkDTRqPLvJOAE3LzhWRdW3mmlO4YaJRVS+OdqkBNtA7ioPAS5Jbm6pc5GCdm0RC3X59VyE0eNOoh53UN3ithmmQr/beVE/8TGnAxEefBuVykAteEZutQRAZs4WW47uw5f/LNRf0BV5gGWpdKeA3K367Wgp2SW2BSZ/+gjXv6KNZfc= azureuser@Terraform" # Replace with your actual public key content
  }

}

# Add storage account

resource "azurerm_storage_account" "vm-linux" {
  name                     = "csb1003200354c76999fe35"
  resource_group_name      = azurerm_resource_group.vm-linux.name
  location                 = azurerm_resource_group.vm-linux.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}
