terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "dev/gitops-platform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-gitops-dev"
  location = "West Europe"
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-gitops-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

module "networking" {
  source              = "../../modules/networking"
  vnet_name           = "vnet-gitops-dev"
  address_space       = ["10.0.0.0/16"]
  aks_subnet_cidr     = "10.0.1.0/24"
  appgw_subnet_cidr   = "10.0.2.0/24"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

module "aks" {
  source                     = "../../modules/aks"
  cluster_name               = "aks-gitops-dev"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  kubernetes_version         = "1.29"
  node_count                 = 2
  vm_size                    = "Standard_D2s_v3"
  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  acr_name                   = "acrgitoopsdev"
  tags                       = local.tags
}

locals {
  tags = {
    environment = "dev"
    project     = "secure-gitops-platform"
    managed_by  = "terraform"
  }
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "acr_login_server" {
  value = module.aks.acr_login_server
}
