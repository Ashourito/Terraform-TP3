variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
}

variable "prefix" {
  type        = string
  default     = "azurerm_resource_group"
  description = "Prefix of the resource name"
}
