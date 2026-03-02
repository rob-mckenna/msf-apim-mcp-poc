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

variable "ai_foundry_hub_name" {
  description = "Name for the Azure AI Foundry Hub workspace."
  type        = string
  default     = "aif-hub-mcp-poc"
}

variable "ai_foundry_project_name" {
  description = "Name for the Azure AI Foundry Project workspace."
  type        = string
  default     = "aif-proj-mcp-poc"
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
