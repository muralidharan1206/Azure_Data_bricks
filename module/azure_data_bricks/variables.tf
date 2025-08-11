variable "workspace_config" {
  description = "All configuration values for the Databricks workspace."
  type        = any
  default     = {}
}

variable "cluster_config" {
  description = "Cluster configuration"
  type        = any
  default     = null
}

variable "admin_users" {
  type = map(object({
    user_name                  = string
    display_name               = optional(string)
    workspace_access           = optional(bool, true)
    allow_cluster_create       = optional(bool, false)
    allow_instance_pool_create = optional(bool, false)
    databricks_sql_access      = optional(bool, true)
    disable_as_user_deletion   = optional(bool, false)
  }))
  default = {}
}


variable "admin_groups" {
  description = "Map of Databricks admin groups and their SCIM properties."
  type = map(object({
    display_name               = string
    allow_cluster_create       = optional(bool, false)
    allow_instance_pool_create = optional(bool, false)
    databricks_sql_access      = optional(bool, true)
    disable_as_user_deletion   = optional(bool, false)
    workspace_access           = optional(bool, true)
  }))
  default = {}
}

variable "access_connectors" {
  description = "Map of Databricks access connectors to create."
  type = map(object({
    name                = string
    location            = string
    resource_group_name = string
    identity_type       = string # SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned
    identity_ids        = optional(list(string), [])
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "databricks_vnet_peering" {
  description = "Map of Databricks virtual network peerings to create."
  type = map(object({
    name                          = string
    resource_group_name           = string
    remote_address_space_prefixes = list(string)
    remote_virtual_network_id     = string
    allow_virtual_network_access  = optional(bool, true)
    allow_forwarded_traffic       = optional(bool, false)
    allow_gateway_transit         = optional(bool, false)
    use_remote_gateways           = optional(bool, false)
  }))
  default = {}
}

variable "vnet_peerings" {
  description = "Map of VNet peering configurations."
  type = map(object({
    name                         = string
    resource_group_name          = string
    virtual_network_name         = string
    remote_virtual_network_id    = string
    allow_virtual_network_access = optional(bool, true)
  }))
  default = {}
}

variable "assign_workspace_admin" {
  description = "Whether to assign admin users to the workspace 'admins' group"
  type        = bool
  default     = false
}

# variable "workspace_url" {
#   type    = string
#   default = null
#   validation {
#     condition     = var.workspace_url != null || (length(var.admin_users) == 0 && length(var.admin_groups) == 0 && length(var.cluster_config) == 0)
#     error_message = "workspace_url must be provided if users, groups, or clusters are being created."
#   }
# }
