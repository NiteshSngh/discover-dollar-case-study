terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
provider "azurerm" {

  subscription_id = "3b229f60-77d0-48f1-a109-XXXXXXXXX"
  tenant_id       = "66dde36c-937b-47ba-XXXX-XXXXXXXXX"

  features {}
}

resource "azurerm_resource_group" "sample" {
  name     = "rg"
  location = "Central India"
}

resource "azurerm_virtual_network" "sample" {
  name                = "sample-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.sample.location
  resource_group_name = azurerm_resource_group.sample.name
}

resource "azurerm_subnet" "sample" {
  name                 = "sample-subnet"
  resource_group_name  = azurerm_resource_group.sample.name
  virtual_network_name = azurerm_virtual_network.sample.name
  address_prefixes      = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "sample" {
  name                = "sample-nic"
  location            = azurerm_resource_group.sample.location
  resource_group_name = azurerm_resource_group.sample.name

  ip_configuration {
    name                          = "ip-config"
    subnet_id                     = azurerm_subnet.sample.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "sample" {
  name                  = "demo-vm"
  location              = azurerm_resource_group.sample.location
  resource_group_name   = azurerm_resource_group.sample.name
  network_interface_ids = [azurerm_network_interface.sample.id]
  vm_size                  = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "demo-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostvm"
    admin_username = "hostadmin"
    admin_password = "Password@123"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}