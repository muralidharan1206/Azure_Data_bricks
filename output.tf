output "workspace_id" {
  value = azurerm_databricks_workspace.databricks.workspace_id
}

output "access_connector_ids" {
  value = {
    for k, v in azurerm_databricks_access_connector.access_connector :
    k => v.id
  }
}
output "workspace_url" {
  value = azurerm_databricks_workspace.databricks.workspace_url
}

output "managed_resource_group_id" {
  value = azurerm_databricks_workspace.databricks.managed_resource_group_id
}

output "disk_encryption_set_id" {
  value = azurerm_databricks_workspace.databricks.disk_encryption_set_id
}

output "storage_account_identity" {
  value = azurerm_databricks_workspace.databricks.storage_account_identity
}

output "managed_disk_identity" {
  value = azurerm_databricks_workspace.databricks.managed_disk_identity
}
