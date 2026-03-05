# msf-apim-mcp-poc

POC demonstrating Microsoft AI Foundry, Azure API Management (APIM) MCP Servers, and the MS Agent Framework.

## Overview

This repository contains:

1. **Terraform infrastructure** that provisions the Azure resources (APIM, APIs, MCP servers, AI Foundry).
2. **A .NET 8 multi-agent application** ([`agents/MultiAgentWorkflow`](agents/MultiAgentWorkflow/README.md)) built with the [Microsoft Agent Framework](https://github.com/microsoft/agent-framework) that connects to the APIM MCP servers.

### Infrastructure Resources

| Resource | Description |
|---|---|
| **Azure Resource Group** | Container for all POC resources |
| **Microsoft Foundry Resource** | AI services account (`Microsoft.CognitiveServices/accounts`) used as the parent for Foundry projects |
| **Microsoft Foundry Project** | Project workspace (`Microsoft.CognitiveServices/accounts/projects`) for AI assets and deployments |
| **Azure API Management (Standard v2)** | APIM gateway hosting the mock APIs and MCP servers |
| **Application Insights** | Central telemetry sink for APIM API diagnostics and request traces |
| **Weather API** | Mock REST API with two operations and static JSON responses |
| **Products API** | Mock REST API with two operations and static JSON responses |
| **Weather MCP Server** | APIM MCP server exposing the Weather API as AI-consumable tools |
| **Products MCP Server** | APIM MCP server exposing the Products API as AI-consumable tools |

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│Architecture: Multi-agent workflow and infrastructure                         │
│                                                                              │
│┌──────────────────────┐                                                      │
││     Client/User      │                                                      │
│└──────────┬───────────┘                                                      │
│           │                                                                  │
│           v                                                                  │
│┌────────────────────────────────────────────────────┐                        │
││ .NET 8 App: agents/MultiAgentWorkflow              │                        │
││  MultiAgentOrchestratorAgent                       │                        │
││   ├─ WeatherAgent  ── MCP /weather-mcp/mcp  ──┐    │                        │
││   └─ ProductsAgent ── MCP /products-mcp/mcp ──┘    │                        │
│└────────────────────────────────────────────────────┘                        │
│                                                                              │
│Azure Resource Group (Terraform-managed infrastructure)                       │
│┌────────────────────────────────────────────────────┐                        │
││ Azure API Management (Standard v2)                 │                        │
││  Weather MCP Server  ────────────────> Weather API │                        │
││  Products MCP Server ───────────────> Products API │                        │
│└────────────────────────────────────────────────────┘                        │
│┌────────────────────────────────────────────────────┐                        │
││ Microsoft Foundry Resource                         │                        │
││  └─ Microsoft Foundry Project                      │                        │
││     (model deployment + agent runtime)             │                        │
│└────────────────────────────────────────────────────┘                        │
│┌────────────────────────────────────────────────────┐                        │
││ Application Insights                               │                        │
││  (APIM diagnostics + agent telemetry)              │                        │
│└────────────────────────────────────────────────────┘                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Mock API Responses

Both APIs use APIM `<mock-response>` policies to return operation response examples as mock JSON payloads. No backend services are required.

> **Tip:** For consistent APIM mock-response behavior, set operation response examples to the `default` example name for each `200 application/json` representation.

### Weather API

**`GET /weather/current?location=London`**

```json
{
  "location": { "name": "London", "country": "GB", "lat": 51.5074, "lon": -0.1278 },
  "current": {
    "temperature_c": 15.2, "temperature_f": 59.4,
    "condition": "Partly cloudy", "humidity": 72,
    "wind_kph": 14.4, "wind_direction": "SW",
    "pressure_mb": 1012, "feels_like_c": 13.8,
    "uv_index": 3, "visibility_km": 10
  },
  "last_updated": "2025-01-15 14:00"
}
```

**`GET /weather/forecast?location=London`**

```json
{
  "location": "London",
  "forecast": [
    { "date": "2025-01-16", "max_temp_c": 17.0, "min_temp_c": 10.0, "condition": "Sunny", "precipitation_mm": 0.0 },
    { "date": "2025-01-17", "max_temp_c": 14.0, "min_temp_c":  8.0, "condition": "Rainy", "precipitation_mm": 12.5 },
    { "date": "2025-01-18", "max_temp_c": 12.0, "min_temp_c":  7.0, "condition": "Cloudy","precipitation_mm": 2.0 }
  ]
}
```

### Products API

**`GET /products/`**

```json
{
  "total": 3,
  "products": [
    { "id": "P001", "name": "Laptop Pro",     "category": "Electronics", "price": 1299.99, "in_stock": true  },
    { "id": "P002", "name": "Wireless Mouse", "category": "Electronics", "price":   29.99, "in_stock": true  },
    { "id": "P003", "name": "Office Chair",   "category": "Furniture",   "price":  349.99, "in_stock": false }
  ]
}
```

**`GET /products/{id}`** (e.g. `/products/P001`)

```json
{
  "id": "P001",
  "name": "Laptop Pro",
  "category": "Electronics",
  "price": 1299.99,
  "in_stock": true,
  "description": "High-performance laptop with 16GB RAM and 512GB SSD, ideal for professionals.",
  "specs": { "processor": "Intel Core i7-1260P", "ram_gb": 16, "storage": "512GB NVMe SSD", "display": "15.6-inch FHD IPS", "battery_h": 12 },
  "rating": { "average": 4.5, "count": 238 }
}
```

## MCP Server Endpoints

After deployment, AI agents connect to the MCP servers at:

| MCP Server | Endpoint |
|---|---|
| Weather MCP Server | `https://<apim-gateway>/weather-mcp/mcp` |
| Products MCP Server | `https://<apim-gateway>/products-mcp/mcp` |

These endpoints speak the [Model Context Protocol](https://modelcontextprotocol.io/) (JSON-RPC over HTTP/SSE). Compatible clients include GitHub Copilot (Agent Mode), VS Code MCP extensions, Claude Desktop, and custom agents built with the Azure AI Agent SDK.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- An active [Azure subscription](https://azure.microsoft.com/free/)
- Azure CLI authenticated (`az login`) or a service principal configured via environment variables

## Deployment

### 1. Clone and navigate

```bash
git clone https://github.com/rob-mckenna/msf-apim-mcp-poc.git
cd msf-apim-mcp-poc/terraform
```

### 2. Initialise providers

```bash
terraform init
```

### 3. Review the plan

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

> **Note:** APIM Standard v2 provisioning takes approximately 5–10 minutes. Microsoft Foundry resource and project provisioning typically takes several minutes.

### 5. Retrieve outputs

```bash
terraform output
```

Key outputs:

| Output | Description |
|---|---|
| `apim_gateway_url` | Base URL of the APIM gateway |
| `weather_mcp_endpoint` | MCP endpoint for the Weather API |
| `products_mcp_endpoint` | MCP endpoint for the Products API |
| `foundry_resource_id` | Resource ID of the Microsoft Foundry resource |
| `foundry_project_id` | Resource ID of the Microsoft Foundry Project |
| `application_insights_id` | Resource ID of the Application Insights instance |

### 6. Test the mock APIs

```bash
GATEWAY=$(terraform output -raw apim_gateway_url)

# Weather – current conditions
curl "$GATEWAY/weather/current?location=London"

# Weather – forecast
curl "$GATEWAY/weather/forecast?location=London"

# Products – list
curl "$GATEWAY/products/"

# Products – single item
curl "$GATEWAY/products/P001"
```

### 7. Connect an MCP client

Example `.vscode/mcp.json` for VS Code with GitHub Copilot (Agent Mode):

```json
{
  "servers": {
    "weather-server": {
      "url": "https://<apim-name>.azure-api.net/weather-mcp/mcp",
      "type": "http"
    },
    "products-server": {
      "url": "https://<apim-name>.azure-api.net/products-mcp/mcp",
      "type": "http"
    }
  }
}
```

Replace `<apim-name>` with the value from `terraform output apim_service_name`.

## APIM MCP Server Availability

The APIM MCP server ARM resource type (`Microsoft.ApiManagement/service/mcpServers`) is preview/limited and might not be available in all subscriptions or regions.

This repo uses `enable_apim_mcp_servers` to control MCP server resource creation:

- `false` (default): deploys APIM + REST APIs only, and MCP endpoint outputs are `null`.
- `true`: attempts to create APIM MCP server resources via Terraform.

Check availability before enabling:

```bash
az provider show -n Microsoft.ApiManagement --query "resourceTypes[?resourceType=='service/mcpServers']" -o json
```

If the command returns a non-empty array, set `enable_apim_mcp_servers = true` in `terraform.tfvars` and run `terraform apply`.

## Create MCP Servers in APIM

If `service/mcpServers` isn't available to Terraform in your tenant, create MCP servers directly in APIM.

### Option A: Terraform-managed (when available)

1. Set `enable_apim_mcp_servers = true` in `terraform.tfvars`.
2. Run `terraform apply`.
3. Confirm outputs `weather_mcp_endpoint` and `products_mcp_endpoint` are populated.

### Option B: APIM portal (manual)

1. Open your API Management instance in Azure portal.
2. In APIM, navigate to the MCP server experience (under AI gateway / MCP servers).
3. Create MCP server `weather-mcp`:
  - Source API: `weather-api`
  - Include operations: `get-current-weather`, `get-weather-forecast`
4. Create MCP server `products-mcp`:
  - Source API: `products-api`
  - Include operations: `list-products`, `get-product-by-id`
5. Save/publish each MCP server and verify endpoints:
  - `https://<apim-name>.azure-api.net/weather-mcp/mcp`
  - `https://<apim-name>.azure-api.net/products-mcp/mcp`
6. Update your MCP client config (`.vscode/mcp.json`) with those endpoint URLs.

## Customization

Override defaults in a `terraform.tfvars` file (not committed – see `.gitignore`):

Start by copying `terraform/terraform.tfvars.example` to `terraform.tfvars` and then update values as needed.

```bash
# PowerShell
Copy-Item terraform.tfvars.example terraform.tfvars

# bash
cp terraform.tfvars.example terraform.tfvars
```

```hcl
location                = "uksouth"
resource_group_name     = "rg-my-poc"
apim_publisher_email    = "me@mycompany.com"
apim_publisher_name     = "My Company"
foundry_resource_name   = "my-foundry"
foundry_project_name    = "my-foundry-project"
enable_apim_mcp_servers = false
tags = {
  environment = "dev"
  owner       = "team-name"
}
```

## Cleanup

```bash
terraform destroy
```

## Application Insights Queries (KQL)

After deployment, APIM API diagnostics are sent to Application Insights. Use these KQL queries in the Logs pane.

### Recent APIM requests (last 30 minutes)

```kusto
requests
| where timestamp > ago(30m)
| where cloud_RoleName contains "apim"
| project timestamp, name, resultCode, duration, success, operation_Id
| order by timestamp desc
```

### Failed APIM requests

```kusto
requests
| where timestamp > ago(24h)
| where cloud_RoleName contains "apim"
| where success == false or toint(resultCode) >= 400
| project timestamp, name, resultCode, duration, operation_Id
| order by timestamp desc
```

### APIM request volume and latency by API operation

```kusto
requests
| where timestamp > ago(24h)
| where cloud_RoleName contains "apim"
| summarize request_count = count(), avg_duration_ms = avg(duration), p95_duration_ms = percentile(duration, 95) by name
| order by request_count desc
```

### Weather vs Products API traffic

```kusto
requests
| where timestamp > ago(24h)
| where cloud_RoleName contains "apim"
| extend api_group = case(name contains "weather", "weather", name contains "products", "products", "other")
| summarize requests = count(), errors = countif(success == false or toint(resultCode) >= 400) by api_group
| order by requests desc
```

### MCP endpoint traffic and errors (when MCP servers are enabled)

```kusto
requests
| where timestamp > ago(24h)
| where cloud_RoleName contains "apim"
| where url has "/weather-mcp/mcp" or url has "/products-mcp/mcp"
| extend mcp_endpoint = case(url has "/weather-mcp/mcp", "weather-mcp", url has "/products-mcp/mcp", "products-mcp", "other")
| summarize requests = count(), errors = countif(success == false or toint(resultCode) >= 400), p95_duration_ms = percentile(duration, 95) by mcp_endpoint
| order by requests desc
```

## Multi-Agent Workflow (.NET 8)

The [`agents/MultiAgentWorkflow`](agents/MultiAgentWorkflow/README.md) directory contains a .NET 8 console application built with the [Microsoft Agent Framework](https://github.com/microsoft/agent-framework) that demonstrates the APIM MCP servers in action.

### Agents

| Agent | MCP Server | Tools |
|---|---|---|
| **ProductsAgent** | `/products-mcp/mcp` | `list-products`, `get-product-by-id` |
| **WeatherAgent** | `/weather-mcp/mcp` | `get-current-weather`, `get-weather-forecast` |

### Workflow

A sequential multi-agent workflow (`AgentWorkflowBuilder.BuildSequential`) chains both agents so that a single query can be answered by both specialists in turn.

### Quick Start

```bash
# Set configuration
export FOUNDRY_RESOURCE="$(cd terraform && terraform output -raw foundry_resource_name)"
export FOUNDRY_PROJECT="$(cd terraform && terraform output -raw foundry_project_name)"
export Foundry__ProjectEndpoint="https://${FOUNDRY_RESOURCE}.services.ai.azure.com/api/projects/${FOUNDRY_PROJECT}"
export Foundry__Deployment="gpt-4o"
export APIM__GatewayUrl="$(cd terraform && terraform output -raw apim_gateway_url)"

# Run
cd agents/MultiAgentWorkflow
dotnet run
```

See [`agents/MultiAgentWorkflow/README.md`](agents/MultiAgentWorkflow/README.md) for full documentation.

## Terraform File Structure

```
terraform/
├── providers.tf      # Provider configuration (azurerm ~> 4.0, azapi ~> 2.0, random ~> 3.0)
├── variables.tf      # Input variables with defaults
├── main.tf           # Core infrastructure: RG, Microsoft Foundry resource + project, APIM, Application Insights
├── apis.tf           # Weather/Products APIs, mock policies, APIM logger and diagnostics
├── mcp-servers.tf    # MCP server resources (azapi_resource – preview ARM feature)
└── outputs.tf        # Key resource outputs
```

## Provider Notes

- **`hashicorp/azurerm ~> 4.0`** – used for stable Azure resources such as Resource Group and API Management.
- **`Azure/azapi ~> 2.0`** – used for `Microsoft.CognitiveServices/accounts`, `Microsoft.CognitiveServices/accounts/projects`, and `Microsoft.ApiManagement/service/mcpServers`.
- **`hashicorp/random ~> 3.0`** – generates a short suffix for globally unique resource names (Foundry resource, APIM).
