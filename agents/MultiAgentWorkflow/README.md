# Multi-Agent Workflow

A .NET 8 console application that implements a multi-agent workflow using the [Microsoft Agent Framework](https://github.com/microsoft/agent-framework). The agents connect to the **Products** and **Weather** MCP servers exposed by Azure API Management (APIM) in this repository.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Multi-Agent Workflow                          │
│                                                                     │
│  ┌───────────────────────────┐   ┌───────────────────────────────┐  │
│  │      ProductsAgent        │   │        WeatherAgent           │  │
│  │                           │   │                               │  │
│  │  MCP Tools:               │   │  MCP Tools:                   │  │
│  │  • list-products          │   │  • get-current-weather        │  │
│  │  • get-product-by-id      │   │  • get-weather-forecast       │  │
│  │                           │   │                               │  │
│  │  MCP Server:              │   │  MCP Server:                  │  │
│  │  /products-mcp/mcp        │   │  /weather-mcp/mcp             │  │
│  └───────────────────────────┘   └───────────────────────────────┘  │
│               │                               │                     │
│               └───────────┬───────────────────┘                     │
│                            ▼                                        │
│             Sequential Workflow (Products → Weather)                │
│             AgentWorkflowBuilder.BuildSequential(...)               │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              APIM Gateway (Azure API Management)
         ┌──────────────────────────────────────────┐
         │  /products-mcp/mcp  →  Products API       │
         │  /weather-mcp/mcp   →  Weather API        │
         └──────────────────────────────────────────┘
```

## Project Structure

```
MultiAgentWorkflow/
├── MultiAgentWorkflow.csproj   # Project file with NuGet dependencies
├── Program.cs                  # Entry point: creates agents, runs demos
├── appsettings.json            # Configuration (endpoint, deployment, APIM URL)
├── Agents/
│   ├── ProductsAgent.cs        # Products specialist agent factory
│   └── WeatherAgent.cs         # Weather specialist agent factory
└── README.md                   # This file
```

## Agents

### ProductsAgent

Connects to the `products-mcp` MCP server and provides access to the Products API tools:

| Tool | API Operation | Description |
|---|---|---|
| `list-products` | `GET /products/` | List all products, optionally filtered by category |
| `get-product-by-id` | `GET /products/{id}` | Get full details of a product by ID |

### WeatherAgent

Connects to the `weather-mcp` MCP server and provides access to the Weather API tools:

| Tool | API Operation | Description |
|---|---|---|
| `get-current-weather` | `GET /weather/current` | Get current weather for a location |
| `get-weather-forecast` | `GET /weather/forecast` | Get a multi-day weather forecast |

## Multi-Agent Workflow

The workflow uses `AgentWorkflowBuilder.BuildSequential` to chain both agents:

1. The user query is sent to **ProductsAgent** first.
2. ProductsAgent uses its MCP tools to answer the products portion of the query.
3. The conversation (including ProductsAgent's response) is passed to **WeatherAgent**.
4. WeatherAgent uses its MCP tools to answer the weather portion.
5. The final response contains contributions from both specialist agents.

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8)
- An Azure OpenAI deployment (e.g. `gpt-4o`) in your Azure subscription
- The APIM instance from this repository deployed with MCP servers enabled
  (`enable_apim_mcp_servers = true`)

## Configuration

Copy `appsettings.json` and update with your values:

```json
{
  "AzureOpenAI": {
    "Endpoint": "https://YOUR-RESOURCE.openai.azure.com/",
    "Deployment": "gpt-4o"
  },
  "APIM": {
    "GatewayUrl": "https://YOUR-APIM.azure-api.net"
  }
}
```

You can also use environment variables (override `appsettings.json`):

```bash
# Linux / macOS
export AzureOpenAI__Endpoint="https://YOUR-RESOURCE.openai.azure.com/"
export AzureOpenAI__Deployment="gpt-4o"
export APIM__GatewayUrl="https://YOUR-APIM.azure-api.net"

# PowerShell
$env:AzureOpenAI__Endpoint = "https://YOUR-RESOURCE.openai.azure.com/"
$env:AzureOpenAI__Deployment = "gpt-4o"
$env:APIM__GatewayUrl = "https://YOUR-APIM.azure-api.net"
```

The application authenticates to Azure OpenAI using [`DefaultAzureCredential`](https://learn.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential).  
Run `az login` before starting the app when developing locally.

### Retrieving the APIM Gateway URL

After running `terraform apply` in the `terraform/` directory:

```bash
cd terraform
terraform output apim_gateway_url
```

## Running the Application

```bash
cd agents/MultiAgentWorkflow
dotnet run
```

### Example Output

```
Connecting to APIM MCP servers and creating agents...
  ✓ ProductsAgent ready
  ✓ WeatherAgent ready

=== Products Agent Demo ===
User: What Electronics products are available in the catalog? List them with prices.

ProductsAgent: The Electronics products available are:
  - Laptop Pro (ID: P001) – £1,299.99 – In stock
  - Wireless Mouse (ID: P002) – £29.99 – In stock

=== Weather Agent Demo ===
User: What is the current weather in London? Also give me a 3-day forecast.

WeatherAgent: Current weather in London: Partly cloudy, 15.2°C (feels like 13.8°C),
humidity 72%, wind 14.4 kph SW.

3-day forecast:
  - 2025-01-16: Sunny, high 17°C / low 10°C
  - 2025-01-17: Rainy, high 14°C / low 8°C
  - 2025-01-18: Cloudy, high 12°C / low 7°C

=== Multi-Agent Workflow Demo ===
Building sequential workflow: ProductsAgent → WeatherAgent

User: What Electronics products are available and what is the current weather in London? ...

[ProductsAgent]: The Electronics products in the catalog are:
  - Laptop Pro (P001): £1,299.99 – In stock
  - Wireless Mouse (P002): £29.99 – In stock

[WeatherAgent]: Current weather in London: Partly cloudy, 15.2°C ...
```

## NuGet Packages

| Package | Purpose |
|---|---|
| `Microsoft.Agents.AI` | Core Microsoft Agent Framework |
| `Microsoft.Agents.AI.OpenAI` | Azure OpenAI / OpenAI agent integration |
| `Microsoft.Agents.AI.Workflows` | Multi-agent workflow orchestration |
| `ModelContextProtocol.Core` | MCP client for connecting to MCP servers |
| `Azure.AI.OpenAI` | Azure OpenAI SDK |
| `Azure.Identity` | Azure credential providers (DefaultAzureCredential) |
