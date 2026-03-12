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
  description = "MCP server endpoint for the Weather API when APIM MCP servers are enabled; otherwise null."
  value       = var.enable_apim_mcp_servers ? "${azurerm_api_management.main.gateway_url}/weather-mcp/mcp" : null
}

output "products_mcp_endpoint" {
  description = "MCP server endpoint for the Products API when APIM MCP servers are enabled; otherwise null."
  value       = var.enable_apim_mcp_servers ? "${azurerm_api_management.main.gateway_url}/products-mcp/mcp" : null
}

output "apim_mcp_precheck" {
  description = "APIM MCP precheck status for troubleshooting (CLI install/login and mcpServers availability)."
  value = {
    enabled                 = var.enable_apim_mcp_precheck
    az_cli_installed        = local.apim_mcp_precheck_az_cli_installed
    az_logged_in            = local.apim_mcp_precheck_az_logged_in
    resource_type_available = local.apim_mcp_precheck_resource_type_available
    error_message           = local.apim_mcp_precheck_error_message
  }
}

output "foundry_resource_id" {
  description = "Resource ID of the Microsoft Foundry resource (AIServices account)."
  value       = azapi_resource.foundry.id
}

output "foundry_project_id" {
  description = "Resource ID of the Microsoft Foundry Project."
  value       = azapi_resource.foundry_project.id
}

output "foundry_resource_name" {
  description = "Name of the Microsoft Foundry resource."
  value       = azapi_resource.foundry.name
}

output "foundry_project_name" {
  description = "Name of the Microsoft Foundry Project."
  value       = azapi_resource.foundry_project.name
}

output "application_insights_id" {
  description = "Resource ID of the Application Insights instance used by APIM diagnostics."
  value       = azurerm_application_insights.main.id
}

output "application_insights_name" {
  description = "Name of the Application Insights instance used by APIM diagnostics."
  value       = azurerm_application_insights.main.name
}

output "application_insights_connection_string" {
  description = "Connection string for the Application Insights instance used by APIM diagnostics."
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}
