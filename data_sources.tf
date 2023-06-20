provider "azurerm" {
  alias           = "p"
  subscription_id = var.subscription_id
  features {}
}

data "azurerm_private_dns_zone" "pdn-datalake" {
  provider            = azurerm.p
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.vnet_resource_group_name
}

data "azurerm_subnet" "sn_misc" {
  name                                           = var.subnet_names["misc"]
  resource_group_name                            = var.vnet_resource_group_name
  virtual_network_name                           = var.vnet_name
}

data "azurerm_subnet" "sn_aks" {
  name                                           = var.subnet_names["aks"]
  resource_group_name                            = var.vnet_resource_group_name
  virtual_network_name                           = var.vnet_name
}

data "azurerm_user_assigned_identity" "uai" {
    name = var.aks_uai_name
    resource_group_name = var.resource_group_name
}

