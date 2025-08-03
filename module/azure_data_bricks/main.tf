resource "azurerm_databricks_workspace" "databricks" {
  name                                                = local.name
  resource_group_name                                 = local.resource_group_name
  location                                            = local.location
  sku                                                 = local.sku
  managed_resource_group_name                         = "${local.name}-managed-rg"
  tags                                                = local.tags
  public_network_access_enabled                       = local.public_network_access_enabled
  infrastructure_encryption_enabled                   = local.use_infrastructure_encryption_enabled
  customer_managed_key_enabled                        = local.use_customer_managed_key_enabled
  access_connector_id                                 = local.use_access_connector_id
  default_storage_firewall_enabled                    = local.use_default_storage_firewall_enabled
  network_security_group_rules_required               = local.use_network_security_group_rules_required
  managed_services_cmk_key_vault_id                   = local.managed_services_cmk_key_vault_id
  managed_disk_cmk_key_vault_id                       = local.managed_disk_cmk_key_vault_id
  managed_services_cmk_key_vault_key_id               = local.use_managed_services_cmk_key_vault_key_id
  managed_disk_cmk_key_vault_key_id                   = local.use_managed_disk_cmk_key_vault_key_id
  managed_disk_cmk_rotation_to_latest_version_enabled = local.use_managed_disk_cmk_rotation_to_latest_version_enabled
  load_balancer_backend_address_pool_id               = local.load_balancer_backend_address_pool_id

  dynamic "custom_parameters" {
    for_each = local.custom_parameters
    content {
      machine_learning_workspace_id                        = try(custom_parameters.value.machine_learning_workspace_id, null)
      nat_gateway_name                                     = try(custom_parameters.value.nat_gateway_name, null)
      public_ip_name                                       = try(custom_parameters.value.public_ip_name, null)
      no_public_ip                                         = try(custom_parameters.value.no_public_ip, null)
      public_subnet_name                                   = try(custom_parameters.value.public_subnet_name, null)
      public_subnet_network_security_group_association_id  = try(custom_parameters.value.public_subnet_network_security_group_association_id, null)
      private_subnet_name                                  = try(custom_parameters.value.private_subnet_name, null)
      private_subnet_network_security_group_association_id = try(custom_parameters.value.private_subnet_network_security_group_association_id, null)
      storage_account_name                                 = try(custom_parameters.value.storage_account_name, null)
      storage_account_sku_name                             = try(custom_parameters.value.storage_account_sku_name, null)
      virtual_network_id                                   = try(custom_parameters.value.virtual_network_id, null)
      vnet_address_prefix                                  = try(custom_parameters.value.vnet_address_prefix, null)
    }
  }

  dynamic "enhanced_security_compliance" {
    for_each = local.sku == "premium" && local.enhanced_security_compliance != null ? [local.enhanced_security_compliance] : []
    content {
      automatic_cluster_update_enabled      = try(enhanced_security_compliance.value.automatic_cluster_update_enabled, false)
      compliance_security_profile_enabled   = try(enhanced_security_compliance.value.compliance_security_profile_enabled, false)
      compliance_security_profile_standards = try(enhanced_security_compliance.value.compliance_security_profile_standards, null)
      enhanced_security_monitoring_enabled  = try(enhanced_security_compliance.value.enhanced_security_monitoring_enabled, false)
    }
  }

  dynamic "timeouts" {
    for_each = local.timeouts != null ? [local.timeouts] : []
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

resource "databricks_cluster" "this" {
  cluster_name                 = local.cluster_name
  spark_version                = local.spark_version
  node_type_id                 = local.node_type_id
  driver_node_type_id          = local.driver_node_type_id
  autotermination_minutes      = local.autotermination_minutes
  enable_elastic_disk          = local.enable_elastic_disk
  runtime_engine               = local.runtime_engine
  spark_conf                   = local.spark_conf
  custom_tags                  = local.custom_tags
  data_security_mode           = local.data_security_mode
  policy_id                    = local.policy_id
  spark_env_vars               = local.spark_env_vars
  enable_local_disk_encryption = local.enable_local_disk_encryption
  instance_pool_id             = local.instance_pool_id

  dynamic "autoscale" {
    for_each = local.enable_autoscale ? [1] : []
    content {
      min_workers = local.min_workers
      max_workers = local.max_workers
    }
  }

  num_workers = local.enable_autoscale ? null : local.num_workers

  dynamic "library" {
    for_each = [
      for lib in local.libraries : lib
      if length(lib) > 0 && (
        contains(keys(lib), "jar") ||
        contains(keys(lib), "egg") ||
        contains(keys(lib), "whl") ||
        contains(keys(lib), "maven_coordinates") ||
        contains(keys(lib), "pypi_package") ||
        contains(keys(lib), "cran_package")
      )
    ]
    content {
      jar = try(library.value.jar, null)
      egg = try(library.value.egg, null)
      whl = try(library.value.whl, null)

      dynamic "maven" {
        for_each = try(library.value.maven_coordinates, null) != null ? [1] : []
        content {
          coordinates = library.value.maven_coordinates
          exclusions  = try(library.value.maven_exclusions, null)
        }
      }

      dynamic "pypi" {
        for_each = try(library.value.pypi_package, null) != null ? [1] : []
        content {
          package = library.value.pypi_package
          repo    = try(library.value.pypi_repo, null)
        }
      }

      dynamic "cran" {
        for_each = try(library.value.cran_package, null) != null ? [1] : []
        content {
          package = library.value.cran_package
          repo    = try(library.value.cran_repo, null)
        }
      }
    }
  }


  dynamic "init_scripts" {
    for_each = local.init_scripts
    content {
      dbfs {
        destination = init_scripts.value.dbfs.destination
      }
    }
  }

  lifecycle {
    ignore_changes = [autoscale, num_workers]
  }

  depends_on = [
    azurerm_databricks_workspace.databricks
  ]
}

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

resource "databricks_user" "admin_user" {
  for_each = var.admin_users != null && length(var.admin_users) > 0 ? var.admin_users : {}

  user_name        = each.value.user_name
  display_name     = each.value.display_name
  workspace_access = each.value.workspace_access
  #workspace_consume          = each.value.workspace_consume
  allow_cluster_create       = each.value.allow_cluster_create
  allow_instance_pool_create = each.value.allow_instance_pool_create
  databricks_sql_access      = each.value.databricks_sql_access
  disable_as_user_deletion   = each.value.disable_as_user_deletion
  force                      = true
  depends_on = [
    azurerm_databricks_workspace.databricks
  ]
}

resource "databricks_group" "admin_group" {
  for_each                   = var.admin_groups != null && length(var.admin_groups) > 0 ? var.admin_groups : {}
  display_name               = each.value.display_name
  allow_cluster_create       = each.value.allow_cluster_create
  allow_instance_pool_create = each.value.allow_instance_pool_create
  databricks_sql_access      = each.value.databricks_sql_access
  workspace_access           = each.value.workspace_access
  #disable_as_user_deletion   = each.value.disable_as_user_deletion
  force = true
  depends_on = [
    azurerm_databricks_workspace.databricks
  ]
}
