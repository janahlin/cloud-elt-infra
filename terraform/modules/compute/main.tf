resource "azurerm_virtual_machine" "vm" {
  name                  = "elt-vm"
  location              = "East US"
  resource_group_name   = "elt-rg"
  vm_size               = "Standard_B2s"
}