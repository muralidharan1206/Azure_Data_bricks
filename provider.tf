terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "=1.85.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = ""

}

provider "databricks" {
  alias = "ws"
  host  = ""
}
