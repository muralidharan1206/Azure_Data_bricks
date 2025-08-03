terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "71c0a5c7-51ff-46d8-8142-ebb7e2e78dc1"
}

provider "databricks" {
  alias = "dev2"
  host  = module.databricks["dev2"].workspace_url
}