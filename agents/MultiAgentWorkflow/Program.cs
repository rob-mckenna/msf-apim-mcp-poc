using System;
using System.Threading;
using System.Threading.Tasks;
using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;
using Microsoft.Extensions.Configuration;
using MultiAgentWorkflow.Agents;
using OpenAI.Chat;

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
var configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
    .AddJsonFile("appsettings.local.json", optional: true, reloadOnChange: false)
    .AddEnvironmentVariables()
    .Build();

var foundryProjectEndpoint = configuration["Foundry:ProjectEndpoint"]
    ?? throw new InvalidOperationException(
        "Missing configuration: Foundry:ProjectEndpoint. " +
        "Set it in appsettings.json, appsettings.local.json, or via the FOUNDRY__PROJECTENDPOINT environment variable.");

var modelDeployment = configuration["Foundry:Deployment"]
    ?? throw new InvalidOperationException(
        "Missing configuration: Foundry:Deployment. " +
        "Set it in appsettings.json, appsettings.local.json, or via the FOUNDRY__DEPLOYMENT environment variable.");

var apimGatewayUrl = configuration["APIM:GatewayUrl"]
    ?? throw new InvalidOperationException(
        "Missing configuration: APIM:GatewayUrl. " +
        "Set it in appsettings.json, appsettings.local.json, or via the APIM__GATEWAYURL environment variable.");

var foundryOpenAIEndpoint = ResolveFoundryOpenAIEndpoint(foundryProjectEndpoint);
var foundryTenantId = configuration["Foundry:TenantId"];

// ---------------------------------------------------------------------------
// Azure OpenAI client
// Uses DefaultAzureCredential (supports az login, managed identity, env vars).
// ---------------------------------------------------------------------------
var openAIClient = new AzureOpenAIClient(
    foundryOpenAIEndpoint,
    CreateCredential(foundryTenantId));

ChatClient chatClient = openAIClient.GetChatClient(modelDeployment);

// ---------------------------------------------------------------------------
// Individual Agents
//
// Each agent connects to its respective APIM MCP server and exposes the
// server's tools to the underlying LLM for function-calling.
// ---------------------------------------------------------------------------
Console.WriteLine("Connecting to APIM MCP servers and creating agents...");

var productsAgent = await ProductsAgent.CreateAsync(chatClient, apimGatewayUrl);
Console.WriteLine($"  ✓ {productsAgent.Name} ready");

var weatherAgent = await WeatherAgent.CreateAsync(chatClient, apimGatewayUrl);
Console.WriteLine($"  ✓ {weatherAgent.Name} ready");

Console.WriteLine();

// ---------------------------------------------------------------------------
// Demonstrate individual agents
// ---------------------------------------------------------------------------
Console.WriteLine("=== Products Agent Demo ===");
await RunAgentDemoAsync(
    productsAgent,
    "What Electronics products are available in the catalog? List them with prices.");

Console.WriteLine();
Console.WriteLine("=== Weather Agent Demo ===");
await RunAgentDemoAsync(
    weatherAgent,
    "What is the current weather in London? Also give me a 3-day forecast.");

Console.WriteLine();

// ---------------------------------------------------------------------------
// Multi-Agent Workflow
//
// Uses AgentWorkflowBuilder.BuildSequential to create a workflow where the
// Products agent and Weather agent run in sequence within the same
// conversation. Both agents contribute their specialised knowledge to
// answer a combined query.
// ---------------------------------------------------------------------------
Console.WriteLine("=== Multi-Agent Workflow Demo ===");
Console.WriteLine("Building sequential workflow: ProductsAgent → WeatherAgent");
Console.WriteLine();

Workflow multiAgentWorkflow = AgentWorkflowBuilder.BuildSequential(
    "ProductsAndWeatherWorkflow",
    [productsAgent, weatherAgent]);

await RunMultiAgentWorkflowAsync(
    multiAgentWorkflow,
    "What Electronics products are available and what is the current weather in London? " +
    "I want both product and weather information.");

// ---------------------------------------------------------------------------
// Helper methods
// ---------------------------------------------------------------------------

static async Task RunAgentDemoAsync(
    ChatClientAgent agent,
    string userQuery,
    CancellationToken cancellationToken = default)
{
    Console.WriteLine($"User: {userQuery}");
    Console.WriteLine();

    var session = await agent.CreateSessionAsync(cancellationToken);
    var response = await agent.RunAsync(userQuery, session, null, cancellationToken);

    Console.WriteLine($"{agent.Name}: {response.Text}");
}

static async Task RunMultiAgentWorkflowAsync(
    Workflow workflow,
    string userQuery,
    CancellationToken cancellationToken = default)
{
    Console.WriteLine($"User: {userQuery}");
    Console.WriteLine();

    var sessionId = Guid.NewGuid().ToString();
    StreamingRun streamingRun = await InProcessExecution.RunStreamingAsync(
        workflow,
        userQuery,
        sessionId,
        cancellationToken);

    await foreach (WorkflowEvent evt in streamingRun.WatchStreamAsync(cancellationToken))
    {
        switch (evt)
        {
            case AgentResponseEvent agentResponse:
                Console.WriteLine($"[{agentResponse.ExecutorId}]: {agentResponse.Response.Text}");
                Console.WriteLine();
                break;

            case WorkflowErrorEvent errorEvent:
                Console.Error.WriteLine($"[ERROR]: {errorEvent.Exception?.Message}");
                break;
        }
    }
}

static Uri ResolveFoundryOpenAIEndpoint(string projectEndpoint)
{
    if (!Uri.TryCreate(projectEndpoint, UriKind.Absolute, out var parsed))
    {
        throw new InvalidOperationException(
            "Invalid Foundry project endpoint format. " +
            "Expected format: https://<resource-name>.services.ai.azure.com/api/projects/<project-name>");
    }

    if (!parsed.Host.EndsWith(".services.ai.azure.com", StringComparison.OrdinalIgnoreCase))
    {
        throw new InvalidOperationException(
            "Foundry project endpoint must use a Microsoft Foundry domain (*.services.ai.azure.com). " +
            "Legacy Azure OpenAI endpoints (*.openai.azure.com) aren't supported in this solution.");
    }

    return new Uri($"{parsed.Scheme}://{parsed.Host}");
}

static DefaultAzureCredential CreateCredential(string? tenantId)
{
    if (string.IsNullOrWhiteSpace(tenantId))
    {
        return new DefaultAzureCredential();
    }

    return new DefaultAzureCredential(
        new DefaultAzureCredentialOptions
        {
            TenantId = tenantId,
        });
}
