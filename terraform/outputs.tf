output "resource_group_name" {
  description = "Name of the provisioned Azure Resource Group."
  value       = azurerm_resource_group.main.name
}

output "apim_service_name" {
  description = "Name of the Azure API Management instance."
  value       = azurerm_api_management.main.name
}

output "apim_gateway_url" {
  description = "Base URL of the Azure API Management gateway."
  value       = azurerm_api_management.main.gateway_url
}

output "weather_api_url" {
  description = "Base URL of the Weather mock API."
  value       = "${azurerm_api_management.main.gateway_url}/weather"
}

output "products_api_url" {
  description = "Base URL of the Products mock API."
  value       = "${azurerm_api_management.main.gateway_url}/products"
}

output "weather_mcp_endpoint" {
  description = "MCP server endpoint for the Weather API. AI agents connect here using the Model Context Protocol."
  value       = "${azurerm_api_management.main.gateway_url}/weather-mcp/mcp"
}

output "products_mcp_endpoint" {
  description = "MCP server endpoint for the Products API. AI agents connect here using the Model Context Protocol."
  value       = "${azurerm_api_management.main.gateway_url}/products-mcp/mcp"
}

output "ai_foundry_hub_id" {
  description = "Resource ID of the Azure AI Foundry Hub workspace."
  value       = azurerm_ai_foundry.hub.id
}

output "ai_foundry_project_id" {
  description = "Resource ID of the Azure AI Foundry Project."
  value       = azurerm_ai_foundry_project.project.id
}

output "ai_foundry_hub_name" {
  description = "Name of the Azure AI Foundry Hub workspace."
  value       = azurerm_ai_foundry.hub.name
}

output "ai_foundry_project_name" {
  description = "Name of the Azure AI Foundry Project."
  value       = azurerm_ai_foundry_project.project.name
}
