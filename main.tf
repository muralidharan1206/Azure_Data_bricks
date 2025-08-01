module "databricks" {
  source                  = "./module/databricks"
  for_each                = local.databricks
  name                    = each.value.name
  resource_group_name     = each.value.resource_group_name
  location                = each.value.location
  sku                     = each.value.sku
  tags                    = each.value.tags
  custom_parameters       = try(each.value.custom_parameters, {})
  databricks_vnet_peering = try(each.value.databricks_vnet_peering, {})
  vnet_peerings           = try(each.value.vnet_peerings, {})
  access_connectors       = try(each.value.access_connectors, {})
  admin_users             = try(each.value.admin_users, null)
  admin_groups            = try(each.value.admin_groups, null)
  # aad_group_name          = try(each.value.aad_group_name, null)
  providers = {
    databricks = databricks.ws
  }
}
