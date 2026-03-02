# msf-apim-mcp-poc

POC demonstrating Microsoft AI Foundry, Azure API Management (APIM) MCP Servers, and the MS Agent Framework.

## Overview

This repository contains Terraform infrastructure-as-code that provisions:

| Resource | Description |
|---|---|
| **Azure Resource Group** | Container for all POC resources |
| **Azure AI Foundry Hub** | Central hub workspace for AI Foundry (`azurerm_ai_foundry`) |
| **Azure AI Foundry Project** | AI project workspace linked to the hub (`azurerm_ai_foundry_project`) |
| **Azure API Management (Standard v2)** | APIM gateway hosting the mock APIs and MCP servers |
| **Weather API** | Mock REST API with two operations and static JSON responses |
| **Products API** | Mock REST API with two operations and static JSON responses |
| **Weather MCP Server** | APIM MCP server exposing the Weather API as AI-consumable tools |
| **Products MCP Server** | APIM MCP server exposing the Products API as AI-consumable tools |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Azure AI Foundry Hub                         │   │
│  │   ┌─────────────────────────────────────────────┐   │   │
│  │   │       Azure AI Foundry Project               │   │   │
│  │   └─────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │      Azure API Management (Standard v2)              │   │
│  │                                                     │   │
│  │  ┌──────────────┐    ┌──────────────────────────┐  │   │
│  │  │ Weather API  │    │ Weather MCP Server        │  │   │
│  │  │ GET /current │───▶│ /weather-mcp/mcp          │  │   │
│  │  │ GET /forecast│    │                           │  │   │
│  │  └──────────────┘    └──────────────────────────┘  │   │
│  │                                                     │   │
│  │  ┌──────────────┐    ┌──────────────────────────┐  │   │
│  │  │ Products API │    │ Products MCP Server       │  │   │
│  │  │ GET /        │───▶│ /products-mcp/mcp         │  │   │
│  │  │ GET /{id}    │    │                           │  │   │
│  │  └──────────────┘    └──────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Mock API Responses

Both APIs use APIM `<return-response>` policies to serve static JSON. No backend services are required.

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

> **Note:** APIM Standard v2 provisioning takes approximately 5–10 minutes. AI Foundry Hub provisioning takes approximately 5 minutes.

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
| `ai_foundry_hub_id` | Resource ID of the AI Foundry Hub |
| `ai_foundry_project_id` | Resource ID of the AI Foundry Project |

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

## Customisation

Override defaults in a `terraform.tfvars` file (not committed – see `.gitignore`):

```hcl
location                = "uksouth"
resource_group_name     = "rg-my-poc"
apim_publisher_email    = "me@mycompany.com"
apim_publisher_name     = "My Company"
ai_foundry_hub_name     = "my-ai-hub"
ai_foundry_project_name = "my-ai-project"
tags = {
  environment = "dev"
  owner       = "team-name"
}
```

## Cleanup

```bash
terraform destroy
```

## Terraform File Structure

```
terraform/
├── providers.tf      # Provider configuration (azurerm ~> 4.0, azapi ~> 2.0, random ~> 3.0)
├── variables.tf      # Input variables with defaults
├── main.tf           # Core infrastructure: RG, Storage, Key Vault, AI Foundry Hub & Project, APIM
├── apis.tf           # Weather API and Products API with mock response policies
├── mcp-servers.tf    # MCP server resources (azapi_resource – preview ARM feature)
└── outputs.tf        # Key resource outputs
```

## Provider Notes

- **`hashicorp/azurerm ~> 4.0`** – used for all stable Azure resources including `azurerm_ai_foundry` and `azurerm_ai_foundry_project` (added in 4.3.x / 4.4.x).
- **`Azure/azapi ~> 2.0`** – used for `Microsoft.ApiManagement/service/mcpServers` which is a preview feature not yet available in the azurerm provider.
- **`hashicorp/random ~> 3.0`** – generates a short suffix for globally unique resource names (storage account, Key Vault, APIM).
