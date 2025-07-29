locals {
  yaml_config = try(yamldecode(file(var.yaml_config)), {})
  azure       = try(local.yaml_config.azure, {})
  databricks  = try(local.yaml_config.databricks, {})
}