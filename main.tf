provider "azurerm" {
  features {}
   subscription_id = "479e7ef8-f6ea-410b-a45f-f525de24da85"
  client_id       = "0491dec1-ae70-4227-8a4b-abc301e81e63"
  client_secret   = "LqR8Q~MPSsMRVfRmBxOLTPOWT-85.AWg0yz3MaLx"
  tenant_id       = "f1e36000-ec35-4066-aff2-9eaa65df1924"

}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "example-resources"
  location = "East US"
}

# Create the first virtual network (vnet1)
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space        = ["10.5.0.0/16"]
  location            = "East US"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the second virtual network (vnet2)
resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet2"
  address_space        = ["10.15.0.0/16"]
  location            = "East US"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet for vnet1
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.5.1.0/24"]
}

# Create subnet for vnet2
resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.15.1.0/24"]
}

# Create network peering between vnet1 and vnet2
resource "azurerm_virtual_network_peering" "peering1" {
  name                          = "peering-vnet1-to-vnet2"
  resource_group_name           = azurerm_resource_group.rg.name
  virtual_network_name          = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id     = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access  = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "peering2" {
  name                          = "peering-vnet2-to-vnet1"
  resource_group_name           = azurerm_resource_group.rg.name
  virtual_network_name          = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id     = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access  = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Create a public IP for VM1
resource "azurerm_public_ip" "public_ip1" {
  name                = "public-ip1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create a network interface for VM1
resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                    = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.public_ip1.id
  }
}

# Create VM1 (with Public IP)
resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [azurerm_network_interface.nic1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Add source image reference
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

# Create a network interface for VM2
resource "azurerm_network_interface" "nic2" {
  name                = "nic2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                    = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create VM2 (with Private IP)
resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "vm2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [azurerm_network_interface.nic2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Add source image reference
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

# Outputs for IPs
output "vm1_public_ip" {
  value = azurerm_public_ip.public_ip1.ip_address
}

output "vm2_private_ip" {
  value = azurerm_network_interface.nic2.private_ip_address
}

