resource "azurerm_storage_account" "datalake-storage-account" {
#    count = var.create_datalake ? 1 : 0
 
    name                     = local.datalake_name
    resource_group_name      = var.resource_group_name
    location                 = var.location
    account_kind             = "StorageV2"         
    account_tier             = "Standard"          
    account_replication_type = "LRS"
    cross_tenant_replication_enabled = false
    access_tier =  "Hot"

    public_network_access_enabled = true    #however we are setting network rules to only allow two specific subnets

    min_tls_version               = "TLS1_2"
    is_hns_enabled                = true
    nfsv3_enabled                 = true
    sftp_enabled                  = true

    identity {
        type = "SystemAssigned"
    }
    blob_properties {
        #cors_rule {
        #    #allowed_headers = ""
        #    allowed_methods = ["DELETE","GET","HEAD","MERGE","POST","OPTIONS","PUT","PATCH"]
        #    #allowed_origins = ""
        #    #exposed_headers = ""
        #    #max_age_in_seconds = 600
        #}


        change_feed_enabled = false
        #change_feed_retention_in_days = 365
        #delete_retention_policy {
        #    days = 7
        #}
        #container_delete_retention_policy {
        #  days = 7
        #}

        versioning_enabled = false
        #restore_policy {      # cannot be used becase versioning is disabled
        #    days = 6
        #}

        # default_service_version = "API"
        last_access_time_enabled = false 

    }
    network_rules {
        default_action = "Deny"
        bypass         =["Metrics", "Logging", "AzureServices"]
        virtual_network_subnet_ids = [data.azurerm_subnet.sn_misc.id, data.azurerm_subnet.sn_aks.id ]
        ip_rules       = var.ip_rules   # firewall IP required if nfsv3_enabled
    }    

    tags = var.tags
}


resource "azurerm_private_endpoint" "pe-subnet-misc" {
  name                = "${var.prefix}-pe-datalake-misc"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  subnet_id                = data.azurerm_subnet.sn_misc.id

  private_service_connection {
    name                           = "${var.prefix}-psc-datalake-misc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.datalake-storage-account.id
    subresource_names              = ["blob"]
  }
  depends_on = [azurerm_storage_account.datalake-storage-account]

}

resource "azurerm_private_endpoint" "pe-subnet-aks" {
  name                = "${var.prefix}-pe-datalake-aks"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  subnet_id                = data.azurerm_subnet.sn_aks.id

  private_service_connection {
    name                           = "${var.prefix}-psc-datalake-aks"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.datalake-storage-account.id
    subresource_names              = ["blob"]
  }
  depends_on = [azurerm_storage_account.datalake-storage-account]

}

# Create DNS A Record
resource "azurerm_private_dns_a_record" "dns_a" {
  name                = "${var.prefix}-datalake-sasviya"
  zone_name           = data.azurerm_private_dns_zone.pdn-datalake.name
  resource_group_name = var.vnet_resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-subnet-misc.private_service_connection.0.private_ip_address,
                         azurerm_private_endpoint.pe-subnet-aks.private_service_connection.0.private_ip_address]

  depends_on = [azurerm_private_endpoint.pe-subnet-misc, azurerm_private_endpoint.pe-subnet-aks]
}