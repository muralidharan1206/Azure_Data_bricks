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
  subscription_id = ""
}

provider "databricks" {

}

provider "databricks" {
  alias = "ws"
  host  = ""
}