terraform {
  required_version = ">= 1.9.0" # cross-variable validation (variables.tf)

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    # Used only for the web apps when web_apps_via_azapi = true (see app_service.tf)
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  # State is local (terraform.tfstate) by default. For remote state in an Azure storage
  # account, copy backend.tf.example to backend.tf (git-ignored) and fill it in.
}

provider "azurerm" {
  # azurerm 4.x requires a subscription ID. When var.subscription_id is null the
  # provider falls back to the ARM_SUBSCRIPTION_ID environment variable.
  subscription_id = var.subscription_id

  # Registering resource providers needs subscription-level write access. With only
  # resource-group Contributor, the providers must already be registered (see README).
  resource_provider_registrations = var.deploy_subscription_resources ? "core" : "none"

  features {
    resource_group {
      # Lets `terraform destroy` succeed even if Azure added resources to the group
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      # Purging a deleted vault needs subscription-level permissions. Without them the
      # vault stays soft-deleted (7 days, see key_vault.tf) after `terraform destroy`.
      purge_soft_delete_on_destroy = var.deploy_subscription_resources
    }
    storage {
      # Some storage accounts here have restrictive firewalls on purpose. Without this,
      # the provider's data-plane calls fail with 403 on refresh and destroy.
      data_plane_available = false
    }
  }
}

provider "azapi" {
  subscription_id = var.subscription_id
  # Same reason as resource_provider_registrations above
  skip_provider_registration = !var.deploy_subscription_resources
}

data "azurerm_client_config" "current" {}
