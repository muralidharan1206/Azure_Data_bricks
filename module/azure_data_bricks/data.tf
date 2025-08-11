# Data sources to dynamically fetch supported spark version and node types

data "databricks_spark_version" "latest" {
  count             = try(var.cluster_config.use_dynamic_cluster_settings, false) ? 1 : 0
  latest            = true
  long_term_support = true
}

data "databricks_node_type" "general_purpose" {
  count      = try(var.cluster_config.use_dynamic_cluster_settings, false) ? 1 : 0
  local_disk = true
  category   = "General Purpose"
}

data "databricks_group" "admins" {
  display_name = "admins"
}
