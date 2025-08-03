# Data sources to dynamically fetch supported spark version and node types

data "databricks_spark_version" "latest" {
  latest            = true
  long_term_support = true
}

data "databricks_node_type" "general_purpose" {
  local_disk = true
  category   = "General Purpose"
}