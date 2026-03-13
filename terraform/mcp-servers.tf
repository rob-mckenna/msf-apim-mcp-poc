# ===========================================================================
# MCP Server configurations for Azure API Management
#
# Azure API Management can expose REST APIs as Model Context Protocol (MCP)
# servers, making their operations discoverable and callable as "tools" by
# AI agents (e.g. GitHub Copilot, Azure AI Foundry agents, Claude Desktop).
#
# Resource type : Microsoft.ApiManagement/service/apis
# API version   : 2025-03-01-preview
# Model         : MCP servers are represented as APIM APIs with
#                 properties.type = "mcp".
#
# MCP endpoint format:
#   https://<apim-gateway-url>/<mcp-server-name>/mcp
#
# The azapi provider is used because the azurerm provider does not yet
# expose MCP API fields used by this configuration.
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
  count     = var.enable_apim_mcp_servers ? 1 : 0
  type      = "Microsoft.ApiManagement/service/apis@2025-03-01-preview"
  name      = "weather-mcp;rev=1"
  parent_id = azurerm_api_management.main.id

  body = {
    properties = {
      displayName = "Weather MCP Server"
      description = "MCP server API for weather tools."
      path        = "weather-mcp"
      protocols   = ["https"]
      type        = "mcp"
      mcpTools = [
        {
          name        = "get-current-weather"
          operationId = "/apis/${azurerm_api_management_api.weather.name}/operations/${azurerm_api_management_api_operation.weather_current.operation_id}"
        },
        {
          name        = "get-weather-forecast"
          operationId = "/apis/${azurerm_api_management_api.weather.name}/operations/${azurerm_api_management_api_operation.weather_forecast.operation_id}"
        }
      ]
    }
  }

  # Disable schema validation for MCP fields that may not yet be
  # published in ARM schema metadata.
  schema_validation_enabled = false
  response_export_values    = ["*"]

  depends_on = [
    terraform_data.validate_apim_mcp_precheck,
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
  count     = var.enable_apim_mcp_servers ? 1 : 0
  type      = "Microsoft.ApiManagement/service/apis@2025-03-01-preview"
  name      = "products-mcp;rev=1"
  parent_id = azurerm_api_management.main.id

  body = {
    properties = {
      displayName = "Products MCP Server"
      description = "MCP server API for product tools."
      path        = "products-mcp"
      protocols   = ["https"]
      type        = "mcp"
      mcpTools = [
        {
          name        = "list-products"
          operationId = "/apis/${azurerm_api_management_api.products.name}/operations/${azurerm_api_management_api_operation.products_list.operation_id}"
        },
        {
          name        = "get-product-by-id"
          operationId = "/apis/${azurerm_api_management_api.products.name}/operations/${azurerm_api_management_api_operation.products_get.operation_id}"
        }
      ]
    }
  }

  schema_validation_enabled = false
  response_export_values    = ["*"]

  depends_on = [
    terraform_data.validate_apim_mcp_precheck,
    azurerm_api_management_api_operation.products_list,
    azurerm_api_management_api_operation.products_get,
    azurerm_api_management_api_operation_policy.products_list,
    azurerm_api_management_api_operation_policy.products_get,
  ]
}

