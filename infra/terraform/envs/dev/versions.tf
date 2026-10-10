terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Connection details live in backend.hcl, so this file has no
  # environment-specific values.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  # The subscription is read from the ARM_SUBSCRIPTION_ID environment
  # variable, so no subscription ID is committed to the repo.
}