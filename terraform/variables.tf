variable "location" {
  description = "Azure region where all resources will be deployed."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to create."
  type        = string
  default     = "rg-msf-apim-mcp-poc"
}

variable "apim_publisher_name" {
  description = "Publisher name for the Azure API Management instance."
  type        = string
  default     = "MSF APIM MCP POC"
}

variable "apim_publisher_email" {
  description = "Publisher email address for the Azure API Management instance."
  type        = string
  default     = "admin@example.com"
}

variable "foundry_resource_name" {
  description = "Base name for the Microsoft Foundry resource (AIServices account)."
  type        = string
  default     = "aifoundry-mcp-poc"
}

variable "foundry_project_name" {
  description = "Name for the Microsoft Foundry Project."
  type        = string
  default     = "mcp-poc-project"
}

variable "enable_apim_mcp_servers" {
  description = "Enable APIM MCP server resources (requires Microsoft.ApiManagement/service/mcpServers availability in your subscription/region)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all deployed resources."
  type        = map(string)
  default = {
    environment = "poc"
    project     = "msf-apim-mcp"
    managed_by  = "terraform"
  }
}
