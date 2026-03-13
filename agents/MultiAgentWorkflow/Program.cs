using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
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

var apimSubscriptionKey = configuration["APIM:SubscriptionKey"]
    ?? throw new InvalidOperationException(
        "Missing configuration: APIM:SubscriptionKey. " +
        "Set it in appsettings.local.json or via the APIM__SUBSCRIPTIONKEY environment variable.");

var foundryOpenAIEndpoint = ResolveFoundryOpenAIEndpoint(foundryProjectEndpoint);
var foundryTenantId = configuration["Foundry:TenantId"];
var appInsightsConnectionString = configuration["ApplicationInsights:ConnectionString"];
var telemetryClient = CreateTelemetryClient(appInsightsConnectionString);

if (telemetryClient is not null)
{
    RegisterExceptionTelemetryHandlers(telemetryClient);
    telemetryClient.TrackEvent(
        "ApplicationStarted",
        new Dictionary<string, string>
        {
            ["FoundryEndpointHost"] = foundryOpenAIEndpoint.Host,
            ["ModelDeployment"] = modelDeployment,
        });
}

try
{
    var openAIClient = new AzureOpenAIClient(
        foundryOpenAIEndpoint,
        CreateCredential(foundryTenantId));

    ChatClient chatClient = openAIClient.GetChatClient(modelDeployment);

    Console.WriteLine("Connecting to APIM MCP servers and creating agents...");
    var setupStopwatch = Stopwatch.StartNew();

    var productsAgent = await ProductsAgent.CreateAsync(chatClient, apimGatewayUrl, apimSubscriptionKey);
    Console.WriteLine($"  ✓ {productsAgent.Name} ready");

    var weatherAgent = await WeatherAgent.CreateAsync(chatClient, apimGatewayUrl, apimSubscriptionKey);
    Console.WriteLine($"  ✓ {weatherAgent.Name} ready");

    setupStopwatch.Stop();
    telemetryClient?.TrackMetric("AgentSetupDurationMs", setupStopwatch.Elapsed.TotalMilliseconds);
    telemetryClient?.TrackEvent(
        "AgentsConnected",
        new Dictionary<string, string>
        {
            ["ProductsAgent"] = productsAgent.Name ?? string.Empty,
            ["WeatherAgent"] = weatherAgent.Name ?? string.Empty,
        });

    Console.WriteLine();

    Console.WriteLine("=== Products Agent Demo ===");
    await RunAgentDemoAsync(
        productsAgent,
        "What Electronics products are available in the catalog? List them with prices.",
        telemetryClient,
        "ProductsAgentDemo");

    Console.WriteLine();
    Console.WriteLine("=== Weather Agent Demo ===");
    await RunAgentDemoAsync(
        weatherAgent,
        "What is the current weather in London? Also give me a 3-day forecast.",
        telemetryClient,
        "WeatherAgentDemo");

    Console.WriteLine();

    Console.WriteLine("=== Multi-Agent Workflow Demo ===");
    Console.WriteLine("Building sequential workflow: ProductsAgent → WeatherAgent");
    Console.WriteLine();

    Workflow multiAgentWorkflow = AgentWorkflowBuilder.BuildSequential(
        "ProductsAndWeatherWorkflow",
        [productsAgent, weatherAgent]);

    await RunMultiAgentWorkflowAsync(
        multiAgentWorkflow,
        "What Electronics products are available and what is the current weather in London? " +
        "I want both product and weather information.",
        telemetryClient);

    telemetryClient?.TrackEvent("ApplicationCompleted");
}
catch (Exception ex)
{
    telemetryClient?.TrackEvent(
        "ApplicationFailed",
        new Dictionary<string, string>
        {
            ["ExceptionType"] = ex.GetType().Name,
            ["Message"] = ex.Message,
        });
    telemetryClient?.TrackException(ex);
    throw;
}
finally
{
    if (telemetryClient is not null)
    {
        telemetryClient.Flush();
        await Task.Delay(2000);
    }
}

// ---------------------------------------------------------------------------
// Helper methods
// ---------------------------------------------------------------------------

static async Task RunAgentDemoAsync(
    ChatClientAgent agent,
    string userQuery,
    TelemetryClient? telemetryClient,
    string scenarioName,
    CancellationToken cancellationToken = default)
{
    Console.WriteLine($"User: {userQuery}");
    Console.WriteLine();

    var stopwatch = Stopwatch.StartNew();
    var session = await agent.CreateSessionAsync(cancellationToken);
    var response = await agent.RunAsync(userQuery, session, null, cancellationToken);
    stopwatch.Stop();

    telemetryClient?.TrackMetric($"{scenarioName}DurationMs", stopwatch.Elapsed.TotalMilliseconds);
    telemetryClient?.TrackEvent(
        "AgentDemoCompleted",
        new Dictionary<string, string>
        {
            ["Scenario"] = scenarioName,
            ["AgentName"] = agent.Name ?? string.Empty,
        });

    Console.WriteLine($"{agent.Name}: {response.Text}");
}

static async Task RunMultiAgentWorkflowAsync(
    Workflow workflow,
    string userQuery,
    TelemetryClient? telemetryClient,
    CancellationToken cancellationToken = default)
{
    Console.WriteLine($"User: {userQuery}");
    Console.WriteLine();

    var responseCount = 0;
    var errorCount = 0;
    var stopwatch = Stopwatch.StartNew();
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
                responseCount++;
                Console.WriteLine($"[{agentResponse.ExecutorId}]: {agentResponse.Response.Text}");
                Console.WriteLine();
                break;

            case WorkflowErrorEvent errorEvent:
                errorCount++;
                Console.Error.WriteLine($"[ERROR]: {errorEvent.Exception?.Message}");
                break;
        }
    }

    stopwatch.Stop();
    telemetryClient?.TrackMetric("MultiAgentWorkflowDurationMs", stopwatch.Elapsed.TotalMilliseconds);
    telemetryClient?.TrackMetric("MultiAgentWorkflowResponseCount", responseCount);
    telemetryClient?.TrackMetric("MultiAgentWorkflowErrorCount", errorCount);
    telemetryClient?.TrackEvent(
        "MultiAgentWorkflowCompleted",
        new Dictionary<string, string>
        {
            ["WorkflowName"] = workflow.Name ?? string.Empty,
            ["SessionId"] = sessionId,
            ["ResponseCount"] = responseCount.ToString(),
            ["ErrorCount"] = errorCount.ToString(),
        });
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

static TelemetryClient? CreateTelemetryClient(string? connectionString)
{
    if (string.IsNullOrWhiteSpace(connectionString))
    {
        return null;
    }

    var configuration = TelemetryConfiguration.CreateDefault();
    configuration.ConnectionString = connectionString;
    return new TelemetryClient(configuration);
}

static void RegisterExceptionTelemetryHandlers(TelemetryClient telemetryClient)
{
    AppDomain.CurrentDomain.UnhandledException += (_, args) =>
    {
        if (args.ExceptionObject is Exception exception)
        {
            telemetryClient.TrackException(exception);
            telemetryClient.Flush();
        }
    };

    TaskScheduler.UnobservedTaskException += (_, args) =>
    {
        telemetryClient.TrackException(args.Exception);
        telemetryClient.Flush();
    };
}
