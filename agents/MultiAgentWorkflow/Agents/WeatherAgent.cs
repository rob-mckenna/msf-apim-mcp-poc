using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Agents.AI;
using ModelContextProtocol.Client;
using ModelContextProtocol.Protocol;
using OpenAI.Chat;

namespace MultiAgentWorkflow.Agents;

/// <summary>
/// Factory for creating a Weather specialist agent that connects to the
/// weather-mcp MCP server in Azure API Management.
///
/// The agent has access to two MCP tools exposed by the Weather API:
///   - get-current-weather  → GET /weather/current
///   - get-weather-forecast → GET /weather/forecast
/// </summary>
public static class WeatherAgent
{
    /// <summary>
    /// Creates a <see cref="ChatClientAgent"/> backed by the weather-mcp MCP server.
    /// </summary>
    /// <param name="chatClient">The underlying Azure OpenAI chat client.</param>
    /// <param name="apimGatewayUrl">
    /// The base APIM gateway URL (e.g. <c>https://apim-mcp-poc-abc123.azure-api.net</c>).
    /// The MCP endpoint is constructed as <c>{apimGatewayUrl}/weather-mcp/mcp</c>.
    /// </param>
    /// <param name="cancellationToken">Optional cancellation token.</param>
    /// <returns>A configured <see cref="ChatClientAgent"/> for weather queries.</returns>
    public static async Task<ChatClientAgent> CreateAsync(
        ChatClient chatClient,
        string apimGatewayUrl,
        CancellationToken cancellationToken = default)
    {
        var mcpEndpoint = new Uri($"{apimGatewayUrl.TrimEnd('/')}/weather-mcp/mcp");

        var transport = new HttpClientTransport(new HttpClientTransportOptions
        {
            Endpoint = mcpEndpoint,
            Name = "weather-mcp",
        });

        var mcpClient = await McpClient.CreateAsync(
            transport,
            new McpClientOptions
            {
                ClientInfo = new Implementation
                {
                    Name = "weather-agent-client",
                    Version = "1.0.0",
                },
            },
            loggerFactory: null,
            cancellationToken);

        IList<McpClientTool> tools = await mcpClient.ListToolsAsync(
            cancellationToken: cancellationToken);

        return chatClient.AsAIAgent(
            instructions: """
                You are a Weather specialist agent with access to real-time weather data.
                Use your available tools to accurately answer questions about current weather
                conditions and multi-day forecasts for any location.
                Always use the get-current-weather tool for current conditions and the
                get-weather-forecast tool when a forecast is requested.
                """,
            name: "WeatherAgent",
            description: "Specialist agent for weather queries using the Weather API MCP server.",
            tools: [.. tools]);
    }
}
