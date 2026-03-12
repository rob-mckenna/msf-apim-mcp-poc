# ===========================================================================
# APIM MCP precheck
#
# Runs before MCP server creation when enabled and validates:
# - Azure CLI is installed
# - Azure CLI is authenticated
# - Microsoft.ApiManagement exposes service/mcpServers
#
# This fails early with clear messages instead of failing deep inside azapi.
# ===========================================================================

data "external" "apim_mcp_precheck" {
  count = var.enable_apim_mcp_servers && var.enable_apim_mcp_precheck ? 1 : 0

  program = [
    "bash",
    "${path.module}/scripts/apim_mcp_precheck.sh",
  ]
}

locals {
  apim_mcp_precheck_az_cli_installed = var.enable_apim_mcp_servers && var.enable_apim_mcp_precheck ? try(data.external.apim_mcp_precheck[0].result.az_cli_installed, "false") : "skipped"
  apim_mcp_precheck_az_logged_in = var.enable_apim_mcp_servers && var.enable_apim_mcp_precheck ? try(data.external.apim_mcp_precheck[0].result.az_logged_in, "false") : "skipped"
  apim_mcp_precheck_resource_type_available = var.enable_apim_mcp_servers && var.enable_apim_mcp_precheck ? try(data.external.apim_mcp_precheck[0].result.mcp_resource_type_available, "false") : "skipped"
  apim_mcp_precheck_error_message = var.enable_apim_mcp_servers && var.enable_apim_mcp_precheck ? try(data.external.apim_mcp_precheck[0].result.error_message, "") : ""
}

resource "terraform_data" "validate_apim_mcp_precheck" {
  count = var.enable_apim_mcp_servers ? 1 : 0

  lifecycle {
    precondition {
      condition = !var.enable_apim_mcp_precheck || local.apim_mcp_precheck_az_cli_installed == "true"
      error_message = "APIM MCP precheck failed: Azure CLI (az) is not installed or not on PATH. Install Azure CLI or set enable_apim_mcp_precheck=false to bypass in CI."
    }

    precondition {
      condition = !var.enable_apim_mcp_precheck || local.apim_mcp_precheck_az_logged_in == "true"
      error_message = "APIM MCP precheck failed: Azure CLI is not logged in. Run 'az login' and retry, or set enable_apim_mcp_precheck=false to bypass in CI."
    }

    precondition {
      condition = !var.enable_apim_mcp_precheck || local.apim_mcp_precheck_resource_type_available == "true"
      error_message = "APIM MCP precheck failed: Microsoft.ApiManagement/service/mcpServers is not available for this subscription/tenant. Disable enable_apim_mcp_servers or enable provider support before applying."
    }
  }
}
