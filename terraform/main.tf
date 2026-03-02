# ---------------------------------------------------------------------------
# Random suffix for globally unique resource names
# ---------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ---------------------------------------------------------------------------
# Current Azure client configuration (tenant/subscription)
# ---------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# Storage Account – required by Azure AI Foundry Hub
# Name must be globally unique, max 24 chars, lowercase alphanumeric only.
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "ai_foundry" {
  name                     = "staifdry${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# ---------------------------------------------------------------------------
# Key Vault – required by Azure AI Foundry Hub
# ---------------------------------------------------------------------------
resource "azurerm_key_vault" "ai_foundry" {
  name                       = "kv-aif-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = var.tags
}

# ---------------------------------------------------------------------------
# Azure AI Foundry Hub
# Provides the central workspace for all AI Foundry projects.
# ---------------------------------------------------------------------------
resource "azurerm_ai_foundry" "hub" {
  name                = var.ai_foundry_hub_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  storage_account_id  = azurerm_storage_account.ai_foundry.id
  key_vault_id        = azurerm_key_vault.ai_foundry.id
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------------------------------------------
# Azure AI Foundry Project
# A logical container for AI assets (models, datasets, deployments) within
# the Foundry Hub.
# ---------------------------------------------------------------------------
resource "azurerm_ai_foundry_project" "project" {
  name               = var.ai_foundry_project_name
  location           = azurerm_ai_foundry.hub.location
  ai_services_hub_id = azurerm_ai_foundry.hub.id
  tags               = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------------------------------------------
# Azure API Management – Standard v2 tier
# The gateway that hosts the mock APIs and exposes them as MCP servers.
# Name must be globally unique.
# ---------------------------------------------------------------------------
resource "azurerm_api_management" "main" {
  name                = "apim-mcp-poc-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = "StandardV2_1"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}
