# ===========================================================================
# MCP Server configurations for Azure API Management
#
# Azure API Management can expose REST APIs as Model Context Protocol (MCP)
# servers, making their operations discoverable and callable as "tools" by
# AI agents (e.g. GitHub Copilot, Azure AI Foundry agents, Claude Desktop).
#
# Resource type : Microsoft.ApiManagement/service/mcpServers
# API version   : 2025-03-01-preview
# Scope         : Service-level (NOT workspace-level – workspaces are
#                 not supported for MCP servers as of this preview).
#
# MCP endpoint format:
#   https://<apim-gateway-url>/<mcp-server-name>/mcp
#
# The azapi provider is used because the azurerm provider does not yet
# expose a dedicated resource for APIM MCP servers (preview feature).
# ===========================================================================

# ---------------------------------------------------------------------------
# MCP Server 1: Weather MCP Server
# Exposes the Weather API's operations as MCP tools:
#   - get-current-weather  → GET /weather/current
#   - get-weather-forecast → GET /weather/forecast
#
# AI agents connect to:
#   https://<apim-gateway>/weather-mcp/mcp
# ---------------------------------------------------------------------------
resource "azapi_resource" "weather_mcp_server" {
  type      = "Microsoft.ApiManagement/service/mcpServers@2025-03-01-preview"
  name      = "weather-mcp"
  parent_id = azurerm_api_management.main.id

  body = {
    properties = {
      displayName = "Weather MCP Server"
      description = "Exposes the Weather API as an MCP server. AI agents can call the get-current-weather and get-weather-forecast tools to retrieve mock weather data for any location."
      apis = [
        {
          id = "${azurerm_api_management.main.id}/apis/${azurerm_api_management_api.weather.name}"
        }
      ]
    }
  }

  # Disable schema validation for preview resource types that may not yet
  # have a published schema in the Azure Resource Manager spec.
  schema_validation_enabled = false

  depends_on = [
    azurerm_api_management_api_operation.weather_current,
    azurerm_api_management_api_operation.weather_forecast,
    azurerm_api_management_api_operation_policy.weather_current,
    azurerm_api_management_api_operation_policy.weather_forecast,
  ]
}

# ---------------------------------------------------------------------------
# MCP Server 2: Products MCP Server
# Exposes the Products API's operations as MCP tools:
#   - list-products    → GET /products/
#   - get-product-by-id → GET /products/{id}
#
# AI agents connect to:
#   https://<apim-gateway>/products-mcp/mcp
# ---------------------------------------------------------------------------
resource "azapi_resource" "products_mcp_server" {
  type      = "Microsoft.ApiManagement/service/mcpServers@2025-03-01-preview"
  name      = "products-mcp"
  parent_id = azurerm_api_management.main.id

  body = {
    properties = {
      displayName = "Products MCP Server"
      description = "Exposes the Products API as an MCP server. AI agents can call the list-products and get-product-by-id tools to query the mock product catalog."
      apis = [
        {
          id = "${azurerm_api_management.main.id}/apis/${azurerm_api_management_api.products.name}"
        }
      ]
    }
  }

  schema_validation_enabled = false

  depends_on = [
    azurerm_api_management_api_operation.products_list,
    azurerm_api_management_api_operation.products_get,
    azurerm_api_management_api_operation_policy.products_list,
    azurerm_api_management_api_operation_policy.products_get,
  ]
}
