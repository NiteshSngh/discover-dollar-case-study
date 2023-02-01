# Configure the Azure Provider
provider "azurerm" {
# whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
subscription_id = "3b229f60-77d0-48f1-XXX-XXXXXXX"
tenant_id = "66dde36c-937b-47ba-9f2c-XXXXXXXXX"
version = "~> 3.0.0"
features {}
}

# Create a resource group
resource "azurerm_resource_group" "example_rg" {
name = "${var.resource_prefix}-RG"
location = var.node_location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example_vnet" {
name = "${var.resource_prefix}-vnet"
resource_group_name = azurerm_resource_group.example_rg.name
location = var.node_location
address_space = var.node_address_space
}

# Create a subnets within the virtual network
resource "azurerm_subnet" "example_subnet" {
name = "${var.resource_prefix}-subnet"
resource_group_name = azurerm_resource_group.example_rg.name
virtual_network_name = azurerm_virtual_network.example_vnet.name
address_prefixes = var.node_address_prefix
}
# Create Public IP
resource "azurerm_public_ip" "example_public_ip" {
count = var.node_count
name = "${var.resource_prefix}-${format("%02d", count.index)}-PublicIP"
#name = “${var.resource_prefix}-PublicIP”
location = azurerm_resource_group.example_rg.location
resource_group_name = azurerm_resource_group.example_rg.name
allocation_method = var.Environment == "Test" ? "Static" : "Dynamic"

tags = {
environment = "Test"
}
}
# Create Network Interface
resource "azurerm_network_interface" "example_nic" {
count = var.node_count
#name = “${var.resource_prefix}-NIC”
name = "${var.resource_prefix}-${format("%02d", count.index)}-NIC"
location = azurerm_resource_group.example_rg.location
resource_group_name = azurerm_resource_group.example_rg.name


ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.example_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = element(azurerm_public_ip.example_public_ip.*.id, count.index)
#public_ip_address_id = azurerm_public_ip.example_public_ip.id
#public_ip_address_id = azurerm_public_ip.example_public_ip.id
  }
}

# Virtual Machine Creation
resource "azurerm_virtual_machine" "example_window_vm" {
count = var.node_count
name = "${var.resource_prefix}-${format("%02d", count.index)}"
#name = "${var.resource_prefix}-VM"
location = azurerm_resource_group.example_rg.location
resource_group_name = azurerm_resource_group.example_rg.name
network_interface_ids = [element(azurerm_network_interface.example_nic.*.id, count.index)]
vm_size = "Standard_DS1_v2"
delete_os_disk_on_termination = true

storage_image_reference {
publisher = "MicrosoftWindowsServer"
offer = "WindowsServer"
sku = "2019-Datacenter"
version = "latest"
}
storage_os_disk {
name = "myosdisk-${count.index}"
caching = "ReadWrite"
create_option = "FromImage"
managed_disk_type = "Standard_LRS"
}
os_profile {
computer_name = "linuxhost"
admin_username = "terminator"
admin_password = "Password@1234"
}
os_profile_windows_config {
 provision_vm_agent = true
}

tags = {
environment = "Test"
}
}