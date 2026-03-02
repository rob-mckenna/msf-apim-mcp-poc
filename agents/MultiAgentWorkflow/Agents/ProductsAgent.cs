using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Agents.AI;
using ModelContextProtocol.Client;
using ModelContextProtocol.Protocol;
using OpenAI.Chat;

namespace MultiAgentWorkflow.Agents;

/// <summary>
/// Factory for creating a Products specialist agent that connects to the
/// products-mcp MCP server in Azure API Management.
///
/// The agent has access to two MCP tools exposed by the Products API:
///   - list-products  → GET /products/
///   - get-product-by-id → GET /products/{id}
/// </summary>
public static class ProductsAgent
{
    /// <summary>
    /// Creates a <see cref="ChatClientAgent"/> backed by the products-mcp MCP server.
    /// </summary>
    /// <param name="chatClient">The underlying Azure OpenAI chat client.</param>
    /// <param name="apimGatewayUrl">
    /// The base APIM gateway URL (e.g. <c>https://apim-mcp-poc-abc123.azure-api.net</c>).
    /// The MCP endpoint is constructed as <c>{apimGatewayUrl}/products-mcp/mcp</c>.
    /// </param>
    /// <param name="cancellationToken">Optional cancellation token.</param>
    /// <returns>A configured <see cref="ChatClientAgent"/> for product catalog queries.</returns>
    public static async Task<ChatClientAgent> CreateAsync(
        ChatClient chatClient,
        string apimGatewayUrl,
        CancellationToken cancellationToken = default)
    {
        var mcpEndpoint = new Uri($"{apimGatewayUrl.TrimEnd('/')}/products-mcp/mcp");

        var transport = new HttpClientTransport(new HttpClientTransportOptions
        {
            Endpoint = mcpEndpoint,
            Name = "products-mcp",
        });

        var mcpClient = await McpClient.CreateAsync(
            transport,
            new McpClientOptions
            {
                ClientInfo = new Implementation
                {
                    Name = "products-agent-client",
                    Version = "1.0.0",
                },
            },
            loggerFactory: null,
            cancellationToken);

        IList<McpClientTool> tools = await mcpClient.ListToolsAsync(
            cancellationToken: cancellationToken);

        return chatClient.AsAIAgent(
            instructions: """
                You are a Products specialist agent with access to a product catalog.
                Use your available tools to accurately answer questions about products,
                categories, pricing, and stock availability.
                Always use the list-products tool to search the catalog and the
                get-product-by-id tool to retrieve full product details when asked.
                """,
            name: "ProductsAgent",
            description: "Specialist agent for product catalog queries using the Products API MCP server.",
            tools: [.. tools]);
    }
}
