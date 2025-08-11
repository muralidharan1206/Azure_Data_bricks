module "databricks" {
  for_each = { for k, v in local.databricks : k => v if try(v.enabled, true) }
  #for_each                = local.databricks != null ? local.databricks : {}
  source                  = "./module/databricks"
  workspace_config        = try(each.value.workspace_config, {})
  cluster_config          = try(each.value.cluster_config, {})
  admin_users             = try(each.value.admin_users, {})
  admin_groups            = try(each.value.admin_groups, {})
  access_connectors       = try(each.value.access_connectors, {})
  databricks_vnet_peering = try(each.value.databricks_vnet_peering, {})
  vnet_peerings           = try(each.value.vnet_peerings, {})
  assign_workspace_admin  = try(each.value.assign_workspace_admin, false)
  providers = {
    databricks = databricks.dev2
  }
}
