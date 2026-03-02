# ---------------------------------------------------------------------------
# Random suffix for globally unique resource names
# ---------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# Microsoft Foundry resource (AIServices account)
# Uses the project-first model instead of legacy hub-based deployment.
# ---------------------------------------------------------------------------
resource "azapi_resource" "foundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = "${var.foundry_resource_name}-${random_string.suffix.result}"
  parent_id = azurerm_resource_group.main.id
  location  = azurerm_resource_group.main.location
  tags     = var.tags
  schema_validation_enabled = false

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = "${var.foundry_resource_name}-${random_string.suffix.result}"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------------------------------------------
# Microsoft Foundry Project
# Child resource under the Microsoft Foundry resource.
# ---------------------------------------------------------------------------
resource "azapi_resource" "foundry_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = var.foundry_project_name
  parent_id = azapi_resource.foundry.id
  location  = azurerm_resource_group.main.location
  tags      = var.tags
  schema_validation_enabled = false

  body = {
    properties = {}
  }

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

resource "azurerm_application_insights" "main" {
  name                = "appi-mcp-poc-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  tags                = var.tags
}
