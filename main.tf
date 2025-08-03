module "databricks" {
  source                  = "./module/azure_data_bricks"
  for_each                = local.databricks
  workspace_config        = try(each.value.workspace_config, {})
  cluster_config          = try(each.value.cluster_config, {})
  admin_users             = try(each.value.admin_users, {})
  admin_groups            = try(each.value.admin_groups, {})
  access_connectors       = try(each.value.access_connectors, {})
  databricks_vnet_peering = try(each.value.databricks_vnet_peering, {})
  vnet_peerings           = try(each.value.vnet_peerings, {})
  providers = {
    databricks = databricks.dev2
  }
}