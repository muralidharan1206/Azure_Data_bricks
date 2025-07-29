resource "azurerm_databricks_workspace" "databricks" {
  name                                                = var.name
  resource_group_name                                 = var.resource_group_name
  location                                            = var.location
  sku                                                 = var.sku
  managed_resource_group_name                         = var.managed_resource_group_name
  tags                                                = var.tags
  public_network_access_enabled                       = var.public_network_access_enabled
  infrastructure_encryption_enabled                   = local.use_infrastructure_encryption_enabled
  customer_managed_key_enabled                        = local.use_customer_managed_key_enabled
  access_connector_id                                 = local.use_access_connector_id
  default_storage_firewall_enabled                    = local.use_default_storage_firewall_enabled
  network_security_group_rules_required               = local.use_network_security_group_rules_required
  managed_services_cmk_key_vault_id                   = var.managed_services_cmk_key_vault_id
  managed_disk_cmk_key_vault_id                       = var.managed_disk_cmk_key_vault_id
  managed_services_cmk_key_vault_key_id               = local.use_managed_services_cmk_key_vault_key_id
  managed_disk_cmk_key_vault_key_id                   = local.use_managed_disk_cmk_key_vault_key_id
  managed_disk_cmk_rotation_to_latest_version_enabled = local.use_managed_disk_cmk_rotation_to_latest_version_enabled
  load_balancer_backend_address_pool_id               = var.load_balancer_backend_address_pool_id
  #default_storage_firewall_enabled                    = local.use_default_storage_firewall_enabled
  #access_connector_id                                 = local.use_access_connector_id
  # access_connector_id                                = local.use_access_connector_and_firewall.access_connector_id
  # default_storage_firewall_enabled                   = local.use_access_connector_and_firewall.default_storage_firewall_enabled

  dynamic "custom_parameters" {
    for_each = var.custom_parameters != null && length(var.custom_parameters) > 0 ? var.custom_parameters : {}
    content {
      machine_learning_workspace_id                        = try(custom_parameters.value.machine_learning_workspace_id, null)
      nat_gateway_name                                     = try(custom_parameters.value.nat_gateway_name, null)
      public_ip_name                                       = try(custom_parameters.value.public_ip_name, null)
      no_public_ip                                         = try(custom_parameters.value.no_public_ip, null)
      public_subnet_name                                   = try(custom_parameters.value.public_subnet_name, null)                                   #Deploy Azure Databricks workspace in your own Virtual Network (VNet)
      public_subnet_network_security_group_association_id  = try(custom_parameters.value.public_subnet_network_security_group_association_id, null)  #Deploy Azure Databricks workspace in your own Virtual Network (VNet)
      private_subnet_name                                  = try(custom_parameters.value.private_subnet_name, null)                                  #Deploy Azure Databricks workspace in your own Virtual Network (VNet)
      private_subnet_network_security_group_association_id = try(custom_parameters.value.private_subnet_network_security_group_association_id, null) #Deploy Azure Databricks workspace in your own Virtual Network (VNet)
      storage_account_name                                 = try(custom_parameters.value.storage_account_name, null)
      storage_account_sku_name                             = try(custom_parameters.value.storage_account_sku_name, null)
      virtual_network_id                                   = try(custom_parameters.value.virtual_network_id, null)  #Deploy Azure Databricks workspace in your own Virtual Network (VNet)
      vnet_address_prefix                                  = try(custom_parameters.value.vnet_address_prefix, null) #to use customize CIDR
    }
  }

  dynamic "enhanced_security_compliance" {
    for_each = var.sku == "premium" && var.enhanced_security_compliance != null ? [var.enhanced_security_compliance] : []
    content {
      automatic_cluster_update_enabled      = try(enhanced_security_compliance.value.automatic_cluster_update_enabled, false)
      compliance_security_profile_enabled   = try(enhanced_security_compliance.value.compliance_security_profile_enabled, false)
      compliance_security_profile_standards = try(enhanced_security_compliance.value.compliance_security_profile_standards, null)
      enhanced_security_monitoring_enabled  = try(enhanced_security_compliance.value.enhanced_security_monitoring_enabled, false)
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [var.timeouts] : []
    content {
      create = try(timeouts.value.create, null)
      read   = try(timeouts.value.read, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }

  depends_on = [
    azurerm_databricks_access_connector.access_connector
  ]
}


# resource "azurerm_databricks_access_connector" "access_connector" {
#   for_each = var.access_connectors != null && length(var.access_connectors) > 0 ? var.access_connectors : {}

#   name                = each.value.name
#   location            = each.value.location
#   resource_group_name = each.value.resource_group_name

#   identity {
#     type = each.value.identity_type
#     identity_ids = (
#       contains(["UserAssigned", "SystemAssigned, UserAssigned"], each.value.identity_type) && length(each.value.identity_ids) > 0
#     ) ? each.value.identity_ids : null
#   }

#   tags = try(each.value.tags, {})
# }

resource "azurerm_databricks_access_connector" "access_connector" {
  for_each = var.access_connectors

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  identity {
    type = each.value.identity_type
    identity_ids = (
      contains(["UserAssigned", "SystemAssigned, UserAssigned"], each.value.identity_type) &&
      length(try(each.value.identity_ids, [])) > 0
    ) ? each.value.identity_ids : null
  }

  tags = try(each.value.tags, {})
}

resource "azurerm_databricks_virtual_network_peering" "databricks_vnet_peering" {
  for_each                      = var.databricks_vnet_peering != null && length(var.databricks_vnet_peering) > 0 ? var.databricks_vnet_peering : {}
  name                          = each.value.name
  resource_group_name           = each.value.resource_group_name
  workspace_id                  = azurerm_databricks_workspace.databricks.id
  remote_address_space_prefixes = each.value.remote_address_space_prefixes
  remote_virtual_network_id     = each.value.remote_virtual_network_id #ID of the remote virtual network
  allow_virtual_network_access  = try(each.value.allow_virtual_network_access, true)
  allow_forwarded_traffic       = try(each.value.allow_forwarded_traffic, false)
  allow_gateway_transit         = try(each.value.allow_gateway_transit, false)
  use_remote_gateways           = try(each.value.use_remote_gateways, false)
}

resource "azurerm_virtual_network_peering" "vnet_peering" {
  for_each                     = var.vnet_peerings != null && length(var.vnet_peerings) > 0 ? var.vnet_peerings : {}
  name                         = each.value.name
  resource_group_name          = each.value.resource_group_name
  virtual_network_name         = each.value.virtual_network_name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_virtual_network_access = try(each.value.allow_virtual_network_access, true)
}

# Create Databricks admin user and assign workspace admin role
# resource "databricks_user" "admin_user" {
#   #provider  = databricks.ws
#   #count     = var.admin_user_email != null ? 1 : 0
#   user_name = var.admin_user_email
#   force     = true
# }

# resource "databricks_user_role" "my_user_role" {
#   #count   = var.admin_user_email != null ? 1 : 0
#   user_id = databricks_user.admin_user.id
#   role    = "workspace-admin"
# }

resource "databricks_user" "admin_user" {
  count     = var.admin_user_email != null ? 1 : 0
  user_name = var.admin_user_email
  force     = true
}

resource "databricks_group" "admins" {
  display_name = "admin"
}

resource "databricks_group_member" "add_user_to_admins" {
  count     = var.admin_user_email != null ? 1 : 0
  group_id  = databricks_group.admins.id
  member_id = databricks_user.admin_user[0].id
}

resource "databricks_group_role" "workspace_admin" {
  count    = var.admin_user_email != null ? 1 : 0
  group_id = databricks_group.admins.id
  role     = "workspace-admin"
}

# resource "databricks_group_role" "workspace_admin" {
#   #provider = databricks.ws
#   count    = var.aad_group_name != null ? 1 : 0
#   group_id = databricks_group.aad_admin_group[0].id
#   role     = "workspace-admin"
# }

# # Create Azure AD group and assign workspace admin role
# resource "databricks_group" "aad_admin_group" {
#   #provider     = databricks.ws
#   count        = var.aad_group_name != null ? 1 : 0
#   display_name = var.aad_group_name # Must match Azure AD group name synced to workspace
# }

# resource "databricks_group_role" "aad_group_workspace_admin" {
#   #provider = databricks.ws
#   count    = var.aad_group_name != null ? 1 : 0
#   group_id = databricks_group.aad_admin_group[0].id
#   role     = "workspace-admin"
# }