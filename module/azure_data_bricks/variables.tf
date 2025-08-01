variable "name" {
  description = "The name of the Databricks Workspace."
  type        = string
}

variable "location" {
  description = "Azure region where the workspace should be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "sku" {
  description = "SKU for the workspace. Possible values: standard, premium, trial."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}

variable "managed_resource_group_name" {
  description = "Optional name of the managed resource group. Changing this forces new resource."
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "infrastructure_encryption_enabled" {
  type    = bool
  default = false
}

variable "customer_managed_key_enabled" {
  type    = bool
  default = false
}

variable "default_storage_firewall_enabled" {
  type    = bool
  default = false
}

variable "access_connector_id" {
  type    = string
  default = null
}

variable "network_security_group_rules_required" {
  type    = string
  default = null
}

variable "managed_services_cmk_key_vault_id" {
  type    = string
  default = null
}

variable "managed_services_cmk_key_vault_key_id" {
  type    = string
  default = null
}

variable "managed_disk_cmk_key_vault_id" {
  type    = string
  default = null
}

variable "managed_disk_cmk_key_vault_key_id" {
  type    = string
  default = null
}

variable "managed_disk_cmk_rotation_to_latest_version_enabled" {
  type    = bool
  default = false
}

variable "load_balancer_backend_address_pool_id" {
  type    = string
  default = null
}

variable "custom_parameters" {
  description = "A map of custom parameters to configure advanced workspace settings"

  type = map(object({
    machine_learning_workspace_id                        = optional(string)
    nat_gateway_name                                     = optional(string)
    public_ip_name                                       = optional(string)
    no_public_ip                                         = optional(bool)
    public_subnet_name                                   = optional(string)
    public_subnet_network_security_group_association_id  = optional(string)
    private_subnet_name                                  = optional(string)
    private_subnet_network_security_group_association_id = optional(string)
    storage_account_name                                 = optional(string)
    storage_account_sku_name                             = optional(string)
    virtual_network_id                                   = optional(string)
    vnet_address_prefix                                  = optional(string)
  }))
  default = {}
  validation {
    condition = alltrue([
      for cp in values(var.custom_parameters) : (
        !contains(keys(cp), "virtual_network_id") ||
        (
          contains(keys(cp), "public_subnet_name") &&
          contains(keys(cp), "public_subnet_network_security_group_association_id") &&
          contains(keys(cp), "private_subnet_name") &&
          contains(keys(cp), "private_subnet_network_security_group_association_id")
        )
      )
    ])
    error_message = "If virtual_network_id is set in custom_parameters, the following must also be set: public_subnet_name, public_subnet_network_security_group_association_id, private_subnet_name, and private_subnet_network_security_group_association_id."
  }
}

variable "enhanced_security_compliance" {
  description = "Optional enhanced security settings for workspace"
  type = object({
    automatic_cluster_update_enabled      = optional(bool)
    compliance_security_profile_enabled   = optional(bool)
    compliance_security_profile_standards = optional(list(string))
    enhanced_security_monitoring_enabled  = optional(bool)
  })
  default = null

  #   validation {
  #     condition = var.enhanced_security_compliance == null || (
  #       !contains(keys(var.enhanced_security_compliance), "compliance_security_profile_standards") ||
  #       lookup(var.enhanced_security_compliance, "compliance_security_profile_enabled", false) == true
  #     )
  #     error_message = "compliance_security_profile_standards can only be set if compliance_security_profile_enabled is true."
  #   }
  validation {
    condition = (
      var.enhanced_security_compliance == null ||
      !contains(
        keys(
          merge({
            automatic_cluster_update_enabled      = null,
            compliance_security_profile_enabled   = null,
            compliance_security_profile_standards = null,
            enhanced_security_monitoring_enabled  = null
          }, var.enhanced_security_compliance)
        ),
        "compliance_security_profile_standards"
      ) ||
      lookup(
        merge({
          automatic_cluster_update_enabled      = null,
          compliance_security_profile_enabled   = false,
          compliance_security_profile_standards = [],
          enhanced_security_monitoring_enabled  = null
        }, var.enhanced_security_compliance),
        "compliance_security_profile_enabled",
        false
      ) == true
    )

    error_message = "compliance_security_profile_standards can only be set if compliance_security_profile_enabled is true."
  }


}

variable "timeouts" {
  description = "A map of timeout configurations for the workspace"

  type = map(object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  }))
  default = {}
}

variable "access_connectors" {
  description = "Map of Databricks access connectors to create."
  type = map(object({
    name                = string
    location            = string
    resource_group_name = string
    identity_type       = string # "SystemAssigned", "UserAssigned", or "SystemAssigned, UserAssigned"
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
  description = "Map of VNet peering configurations"
  type = map(object({
    name                         = string
    resource_group_name          = string
    virtual_network_name         = string
    remote_virtual_network_id    = string # ID of the remote virtual network
    allow_virtual_network_access = optional(bool, true)
  }))
}

#variables for workspace admin
variable "admin_users" {
  description = "Map of Databricks admin users and their SCIM properties"
  type = map(object({
    user_name                  = string
    display_name               = optional(string)
    workspace_access           = optional(bool, true)
    workspace_consume          = optional(bool, true)
    allow_cluster_create       = optional(bool, false)
    allow_instance_pool_create = optional(bool, false)
    databricks_sql_access      = optional(bool, true)
    disable_as_user_deletion   = optional(bool, false)
  }))
}

variable "admin_groups" {
  description = "Map of Databricks admin groups and their SCIM properties"
  type = map(object({
    display_name               = string
    allow_cluster_create       = optional(bool, false)
    allow_instance_pool_create = optional(bool, false)
    databricks_sql_access      = optional(bool, true)
    disable_as_user_deletion   = optional(bool, false)
    workspace_access           = optional(bool, true)
  }))
}
