locals {
  use_infrastructure_encryption_enabled                   = var.sku == "premium" ? var.infrastructure_encryption_enabled : false
  use_customer_managed_key_enabled                        = var.sku == "premium" ? var.customer_managed_key_enabled : false
  use_network_security_group_rules_required               = var.public_network_access_enabled == false ? var.network_security_group_rules_required : null
  use_managed_disk_cmk_rotation_to_latest_version_enabled = var.managed_disk_cmk_key_vault_key_id != null ? var.managed_disk_cmk_rotation_to_latest_version_enabled : null
  use_managed_disk_cmk_key_vault_key_id                   = var.sku == "premium" ? var.managed_disk_cmk_key_vault_key_id : null
  use_managed_services_cmk_key_vault_key_id               = var.sku == "premium" ? var.managed_services_cmk_key_vault_key_id : null
  #use_access_connector_id                                 = var.default_storage_firewall_enabled == true ? var.access_connector_id : null
  #use_default_storage_firewall_enabled                    = var.access_connector_id != null ? var.default_storage_firewall_enabled : null

  access_connector_ids_per_workspace = [
    for k, v in var.access_connectors : azurerm_databricks_access_connector.access_connector[k].id
  ]

  use_access_connector_id = length(local.access_connector_ids_per_workspace) > 0 ? local.access_connector_ids_per_workspace[0] : null

  #use_default_storage_firewall_enabled = local.use_access_connector_id != null ? true : null

  use_default_storage_firewall_enabled = (
    length(local.access_connector_ids_per_workspace) > 0 &&
    length([
      for cp in values(var.custom_parameters) : cp if try(cp.virtual_network_id, null) != null
    ]) > 0
  ) ? true : null

  # use_access_connector_and_firewall = (
  #   var.sku == "premium" &&
  #   length(local.access_connector_ids_per_workspace) > 0
  #   ) ? {
  #   access_connector_id              = local.access_connector_ids_per_workspace[0]
  #   default_storage_firewall_enabled = true
  #   } : {
  #   access_connector_id              = null
  #   default_storage_firewall_enabled = null
  # }
}
