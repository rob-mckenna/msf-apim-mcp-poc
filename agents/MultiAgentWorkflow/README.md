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
├── appsettings.json            # Baseline configuration (safe defaults/placeholders)
├── appsettings.local.json      # Local developer overrides (gitignored)
├── appsettings.local.json.example # Template for local overrides
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
- A Microsoft Foundry project with a model deployment (e.g. `gpt-4o`)
- The APIM instance from this repository deployed with MCP servers enabled
  (`enable_apim_mcp_servers = true`)

## Configuration

Set up local config:

1. Keep `appsettings.json` as baseline.
2. Copy `appsettings.local.json.example` to `appsettings.local.json`.
3. Put your machine-specific values in `appsettings.local.json`.

`appsettings.local.json` is loaded after `appsettings.json` and overrides it.

Example local file:

```json
{
  "Foundry": {
    "ProjectEndpoint": "https://YOUR-RESOURCE.services.ai.azure.com/api/projects/YOUR-PROJECT-NAME",
    "TenantId": "",
    "Deployment": "gpt-4o"
  },
  "ApplicationInsights": {
    "ConnectionString": "InstrumentationKey=YOUR-INSTRUMENTATION-KEY;IngestionEndpoint=https://YOUR-REGION-0.in.applicationinsights.azure.com/"
  },
  "APIM": {
    "GatewayUrl": "https://YOUR-APIM.azure-api.net",
    "SubscriptionKey": "YOUR-APIM-SUBSCRIPTION-KEY"
  }
}
```

`ProjectEndpoint` must be the Foundry project URL format:

`https://<resource-name>.services.ai.azure.com/api/projects/<project-name>`

You can also use environment variables (override both JSON files):

```bash
# Linux / macOS
export Foundry__ProjectEndpoint="https://YOUR-RESOURCE.services.ai.azure.com/api/projects/YOUR-PROJECT-NAME"
# Optional: set only when your dev account can access multiple tenants.
export Foundry__TenantId="YOUR-TENANT-ID"
export Foundry__Deployment="gpt-4o"
export ApplicationInsights__ConnectionString="InstrumentationKey=YOUR-INSTRUMENTATION-KEY;IngestionEndpoint=https://YOUR-REGION-0.in.applicationinsights.azure.com/"
export APIM__GatewayUrl="https://YOUR-APIM.azure-api.net"
export APIM__SubscriptionKey="YOUR-APIM-SUBSCRIPTION-KEY"

# PowerShell
$env:Foundry__ProjectEndpoint = "https://YOUR-RESOURCE.services.ai.azure.com/api/projects/YOUR-PROJECT-NAME"
# Optional: set only when your dev account can access multiple tenants.
$env:Foundry__TenantId = "YOUR-TENANT-ID"
$env:Foundry__Deployment = "gpt-4o"
$env:ApplicationInsights__ConnectionString = "InstrumentationKey=YOUR-INSTRUMENTATION-KEY;IngestionEndpoint=https://YOUR-REGION-0.in.applicationinsights.azure.com/"
$env:APIM__GatewayUrl = "https://YOUR-APIM.azure-api.net"
$env:APIM__SubscriptionKey = "YOUR-APIM-SUBSCRIPTION-KEY"
```

`Foundry:TenantId` is optional but recommended in multi-tenant dev environments to ensure `DefaultAzureCredential` acquires a token from the correct tenant.

`ApplicationInsights:ConnectionString` is optional. If set, the console app emits startup/completion events and unhandled exceptions to Application Insights.

The application authenticates to Azure OpenAI using [`DefaultAzureCredential`](https://learn.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential).  
Run `az login` before starting the app when developing locally.

### Retrieving the APIM Gateway URL

After running `terraform apply` in the `terraform/` directory:

```bash
cd terraform
terraform output apim_gateway_url
```

### Retrieving an APIM Subscription Key

The MCP endpoints in this sample require an APIM subscription key.

```bash
az rest --method post \
  --uri "https://management.azure.com/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.ApiManagement/service/<apim-service-name>/subscriptions/master/listSecrets?api-version=2025-03-01-preview" \
  --query primaryKey -o tsv
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

## Agent Telemetry Queries (KQL)

Use these queries in the Application Insights **Logs** pane to inspect telemetry emitted by the agent process.

### Agent lifecycle events

```kusto
customEvents
| where timestamp > ago(24h)
| where name in ("ApplicationStarted", "AgentsConnected", "ApplicationCompleted", "ApplicationFailed")
| project timestamp, name, customDimensions
| order by timestamp desc
```

### Demo and workflow duration metrics

```kusto
customMetrics
| where timestamp > ago(24h)
| where name in ("AgentSetupDurationMs", "ProductsAgentDemoDurationMs", "WeatherAgentDemoDurationMs", "MultiAgentWorkflowDurationMs")
| summarize avg_value = avg(value), p95_value = percentile(value, 95), samples = count() by name
| order by name asc
```

### Workflow response and error counts

```kusto
customMetrics
| where timestamp > ago(24h)
| where name in ("MultiAgentWorkflowResponseCount", "MultiAgentWorkflowErrorCount")
| summarize total = sum(value), samples = count() by name
```

### Exceptions captured by the agent

```kusto
exceptions
| where timestamp > ago(24h)
| project timestamp, type, outerMessage, operation_Id
| order by timestamp desc
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
| `Microsoft.ApplicationInsights` | Agent process telemetry (events, metrics, exceptions) |
