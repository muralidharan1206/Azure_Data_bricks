locals {
  name                                                = try(var.workspace_config.name, null)
  resource_group_name                                 = try(var.workspace_config.resource_group_name, null)
  location                                            = try(var.workspace_config.location, null)
  sku                                                 = try(var.workspace_config.sku, "standard")
  tags                                                = try(var.workspace_config.tags, {})
  custom_parameters                                   = try(var.workspace_config.custom_parameters, {})
  enhanced_security_compliance                        = try(var.workspace_config.enhanced_security_compliance, null)
  timeouts                                            = try(var.workspace_config.timeouts, null)
  public_network_access_enabled                       = try(var.workspace_config.public_network_access_enabled, true)
  infrastructure_encryption_enabled                   = try(var.workspace_config.infrastructure_encryption_enabled, false)
  customer_managed_key_enabled                        = try(var.workspace_config.customer_managed_key_enabled, false)
  network_security_group_rules_required               = try(var.workspace_config.network_security_group_rules_required, null)
  managed_services_cmk_key_vault_id                   = try(var.workspace_config.managed_services_cmk_key_vault_id, null)
  managed_disk_cmk_key_vault_id                       = try(var.workspace_config.managed_disk_cmk_key_vault_id, null)
  managed_services_cmk_key_vault_key_id               = try(var.workspace_config.managed_services_cmk_key_vault_key_id, null)
  managed_disk_cmk_key_vault_key_id                   = try(var.workspace_config.managed_disk_cmk_key_vault_key_id, null)
  managed_disk_cmk_rotation_to_latest_version_enabled = try(var.workspace_config.managed_disk_cmk_rotation_to_latest_version_enabled, null)
  load_balancer_backend_address_pool_id               = try(var.workspace_config.load_balancer_backend_address_pool_id, null)
  access_connectors                                   = try(var.workspace_config.access_connectors, {})
}

# Workspace derived values
locals {
  use_infrastructure_encryption_enabled                   = local.sku == "premium" ? local.infrastructure_encryption_enabled : false
  use_customer_managed_key_enabled                        = local.sku == "premium" ? local.customer_managed_key_enabled : false
  use_network_security_group_rules_required               = local.public_network_access_enabled == false ? local.network_security_group_rules_required : null
  use_managed_disk_cmk_rotation_to_latest_version_enabled = local.managed_disk_cmk_key_vault_key_id != null ? local.managed_disk_cmk_rotation_to_latest_version_enabled : null
  use_managed_disk_cmk_key_vault_key_id                   = local.sku == "premium" ? local.managed_disk_cmk_key_vault_key_id : null
  use_managed_services_cmk_key_vault_key_id               = local.sku == "premium" ? local.managed_services_cmk_key_vault_key_id : null

  access_connector_ids_per_workspace = [
    for k, v in local.access_connectors : azurerm_databricks_access_connector.access_connector[k].id
  ]

  use_access_connector_id = length(local.access_connector_ids_per_workspace) > 0 ? local.access_connector_ids_per_workspace[0] : null

  use_default_storage_firewall_enabled = (
    length(local.access_connector_ids_per_workspace) > 0 &&
    length([
      for cp in values(local.custom_parameters) : cp if try(cp.virtual_network_id, null) != null
    ]) > 0
  ) ? true : null
}

# Cluster unpacking
locals {
  cluster_name                 = try(var.cluster_config.cluster_name, null)
  spark_version                = try(var.cluster_config.use_dynamic_cluster_settings, false) ? data.databricks_spark_version.latest.id : try(var.cluster_config.spark_version, null)
  node_type_id                 = try(var.cluster_config.use_dynamic_cluster_settings, false) ? data.databricks_node_type.general_purpose.id : try(var.cluster_config.node_type_id, null)
  driver_node_type_id          = try(var.cluster_config.driver_node_type_id, null)
  autotermination_minutes      = try(var.cluster_config.autotermination_minutes, 30)
  enable_elastic_disk          = try(var.cluster_config.enable_elastic_disk, true)
  runtime_engine               = try(var.cluster_config.runtime_engine, "STANDARD")
  spark_conf                   = try(var.cluster_config.spark_conf, {})
  custom_tags                  = try(var.cluster_config.custom_tags, {})
  data_security_mode           = try(var.cluster_config.data_security_mode, null)
  policy_id                    = try(var.cluster_config.policy_id, null)
  spark_env_vars               = try(var.cluster_config.spark_env_vars, {})
  enable_local_disk_encryption = try(var.cluster_config.enable_local_disk_encryption, false)
  instance_pool_id             = try(var.cluster_config.instance_pool_id, null)
  enable_autoscale             = try(var.cluster_config.enable_autoscale, false)
  min_workers                  = try(var.cluster_config.min_workers, null)
  max_workers                  = try(var.cluster_config.max_workers, null)
  num_workers                  = try(var.cluster_config.num_workers, 1)
  libraries                    = try(var.cluster_config.libraries, [])
  init_scripts                 = try(var.cluster_config.init_scripts, [])
}
