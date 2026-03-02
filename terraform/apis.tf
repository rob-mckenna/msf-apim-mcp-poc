# ===========================================================================
# API 1: Weather API
# A mock REST API that returns current weather and forecast data.
# Operations are exposed as MCP tools via the Weather MCP Server.
# ===========================================================================

resource "azurerm_api_management_api" "weather" {
  name                  = "weather-api"
  resource_group_name   = azurerm_resource_group.main.name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "Weather API"
  path                  = "weather"
  protocols             = ["https"]
  description           = "Mock Weather API that returns current conditions and forecasts for any location. All responses are mocked."
  subscription_required = false
}

# ---------------------------------------------------------------------------
# Weather API – Operation: GET /current
# Returns the current weather for a specified location.
# ---------------------------------------------------------------------------
resource "azurerm_api_management_api_operation" "weather_current" {
  operation_id        = "get-current-weather"
  api_name            = azurerm_api_management_api.weather.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Get Current Weather"
  method              = "GET"
  url_template        = "/current"
  description         = "Returns the current weather conditions including temperature, humidity, wind speed, and UV index for the specified location."

  request {
    query_parameter {
      name        = "location"
      required    = true
      type        = "string"
      description = "City name or lat/lon pair (e.g. 'London' or '51.5,-0.1')."
    }
  }

  response {
    status_code = 200
    description = "Current weather data for the requested location."
    representation {
      content_type = "application/json"
      example {
        name = "London"
        value = jsonencode({
          location = {
            name    = "London"
            country = "GB"
            lat     = 51.5074
            lon     = -0.1278
          }
          current = {
            temperature_c  = 15.2
            temperature_f  = 59.4
            condition      = "Partly cloudy"
            humidity       = 72
            wind_kph       = 14.4
            wind_direction = "SW"
            pressure_mb    = 1012
            feels_like_c   = 13.8
            uv_index       = 3
            visibility_km  = 10
          }
          last_updated = "2025-01-15 14:00"
        })
      }
    }
  }
}

# Mock policy: returns a static weather response for any location query.
resource "azurerm_api_management_api_operation_policy" "weather_current" {
  operation_id        = azurerm_api_management_api_operation.weather_current.operation_id
  api_name            = azurerm_api_management_api.weather.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <return-response>
          <set-status code="200" reason="OK" />
          <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
          </set-header>
          <set-body>{
      "location": {
        "name": "London",
        "country": "GB",
        "lat": 51.5074,
        "lon": -0.1278
      },
      "current": {
        "temperature_c": 15.2,
        "temperature_f": 59.4,
        "condition": "Partly cloudy",
        "humidity": 72,
        "wind_kph": 14.4,
        "wind_direction": "SW",
        "pressure_mb": 1012,
        "feels_like_c": 13.8,
        "uv_index": 3,
        "visibility_km": 10
      },
      "last_updated": "2025-01-15 14:00"
    }</set-body>
        </return-response>
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}

# ---------------------------------------------------------------------------
# Weather API – Operation: GET /forecast
# Returns a multi-day weather forecast for a specified location.
# ---------------------------------------------------------------------------
resource "azurerm_api_management_api_operation" "weather_forecast" {
  operation_id        = "get-weather-forecast"
  api_name            = azurerm_api_management_api.weather.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Get Weather Forecast"
  method              = "GET"
  url_template        = "/forecast"
  description         = "Returns a 3-day weather forecast including daily high/low temperatures and conditions for the specified location."

  request {
    query_parameter {
      name        = "location"
      required    = true
      type        = "string"
      description = "City name (e.g. 'London')."
    }
    query_parameter {
      name        = "days"
      required    = false
      type        = "integer"
      description = "Number of forecast days to return (1-5, default 3)."
    }
  }

  response {
    status_code = 200
    description = "Multi-day weather forecast for the requested location."
    representation {
      content_type = "application/json"
      example {
        name = "London"
        value = jsonencode({
          location = "London"
          forecast = [
            { date = "2025-01-16", max_temp_c = 17.0, min_temp_c = 10.0, condition = "Sunny", precipitation_mm = 0.0 },
            { date = "2025-01-17", max_temp_c = 14.0, min_temp_c = 8.0, condition = "Rainy", precipitation_mm = 12.5 },
            { date = "2025-01-18", max_temp_c = 12.0, min_temp_c = 7.0, condition = "Cloudy", precipitation_mm = 2.0 }
          ]
        })
      }
    }
  }
}

# Mock policy: returns a static 3-day forecast.
resource "azurerm_api_management_api_operation_policy" "weather_forecast" {
  operation_id        = azurerm_api_management_api_operation.weather_forecast.operation_id
  api_name            = azurerm_api_management_api.weather.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <return-response>
          <set-status code="200" reason="OK" />
          <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
          </set-header>
          <set-body>{
      "location": "London",
      "forecast": [
        {
          "date": "2025-01-16",
          "max_temp_c": 17.0,
          "min_temp_c": 10.0,
          "condition": "Sunny",
          "precipitation_mm": 0.0
        },
        {
          "date": "2025-01-17",
          "max_temp_c": 14.0,
          "min_temp_c": 8.0,
          "condition": "Rainy",
          "precipitation_mm": 12.5
        },
        {
          "date": "2025-01-18",
          "max_temp_c": 12.0,
          "min_temp_c": 7.0,
          "condition": "Cloudy",
          "precipitation_mm": 2.0
        }
      ]
    }</set-body>
        </return-response>
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}

# ===========================================================================
# API 2: Products API
# A mock REST API for a product catalog. Supports listing products and
# retrieving individual product details.
# Operations are exposed as MCP tools via the Products MCP Server.
# ===========================================================================

resource "azurerm_api_management_api" "products" {
  name                  = "products-api"
  resource_group_name   = azurerm_resource_group.main.name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "Products API"
  path                  = "products"
  protocols             = ["https"]
  description           = "Mock Products API for querying a product catalog. Supports listing products by category and retrieving individual product details. All responses are mocked."
  subscription_required = false
}

# ---------------------------------------------------------------------------
# Products API – Operation: GET /
# Returns a paginated list of products, optionally filtered by category.
# ---------------------------------------------------------------------------
resource "azurerm_api_management_api_operation" "products_list" {
  operation_id        = "list-products"
  api_name            = azurerm_api_management_api.products.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "List Products"
  method              = "GET"
  url_template        = "/"
  description         = "Returns a list of all products in the catalog. Optionally filter by category."

  request {
    query_parameter {
      name        = "category"
      required    = false
      type        = "string"
      description = "Filter products by category (e.g. 'Electronics', 'Furniture')."
    }
  }

  response {
    status_code = 200
    description = "A list of products matching the optional category filter."
    representation {
      content_type = "application/json"
      example {
        name = "default"
        value = jsonencode({
          total = 3
          products = [
            { id = "P001", name = "Laptop Pro", category = "Electronics", price = 1299.99, in_stock = true },
            { id = "P002", name = "Wireless Mouse", category = "Electronics", price = 29.99, in_stock = true },
            { id = "P003", name = "Office Chair", category = "Furniture", price = 349.99, in_stock = false }
          ]
        })
      }
    }
  }
}

# Mock policy: returns a static product list.
resource "azurerm_api_management_api_operation_policy" "products_list" {
  operation_id        = azurerm_api_management_api_operation.products_list.operation_id
  api_name            = azurerm_api_management_api.products.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <return-response>
          <set-status code="200" reason="OK" />
          <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
          </set-header>
          <set-body>{
      "total": 3,
      "products": [
        {
          "id": "P001",
          "name": "Laptop Pro",
          "category": "Electronics",
          "price": 1299.99,
          "in_stock": true
        },
        {
          "id": "P002",
          "name": "Wireless Mouse",
          "category": "Electronics",
          "price": 29.99,
          "in_stock": true
        },
        {
          "id": "P003",
          "name": "Office Chair",
          "category": "Furniture",
          "price": 349.99,
          "in_stock": false
        }
      ]
    }</set-body>
        </return-response>
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}

# ---------------------------------------------------------------------------
# Products API – Operation: GET /{id}
# Returns detailed information about a single product by its ID.
# ---------------------------------------------------------------------------
resource "azurerm_api_management_api_operation" "products_get" {
  operation_id        = "get-product-by-id"
  api_name            = azurerm_api_management_api.products.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Get Product by ID"
  method              = "GET"
  url_template        = "/{id}"
  description         = "Returns the full details of a specific product, including specifications and stock status."

  template_parameter {
    name        = "id"
    required    = true
    type        = "string"
    description = "Unique product identifier (e.g. 'P001')."
  }

  response {
    status_code = 200
    description = "Detailed product information."
    representation {
      content_type = "application/json"
      example {
        name = "P001"
        value = jsonencode({
          id          = "P001"
          name        = "Laptop Pro"
          category    = "Electronics"
          price       = 1299.99
          in_stock    = true
          description = "High-performance laptop with 16GB RAM and 512GB SSD, ideal for professionals."
          specs = {
            processor = "Intel Core i7-1260P"
            ram_gb    = 16
            storage   = "512GB NVMe SSD"
            display   = "15.6-inch FHD IPS"
            battery_h = 12
          }
          rating = {
            average = 4.5
            count   = 238
          }
        })
      }
    }
  }

  response {
    status_code = 404
    description = "Product not found."
    representation {
      content_type = "application/json"
      example {
        name = "not-found"
        value = jsonencode({
          error   = "NotFound"
          message = "Product with the specified ID was not found."
        })
      }
    }
  }
}

# Mock policy: returns a static product detail response.
resource "azurerm_api_management_api_operation_policy" "products_get" {
  operation_id        = azurerm_api_management_api_operation.products_get.operation_id
  api_name            = azurerm_api_management_api.products.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <return-response>
          <set-status code="200" reason="OK" />
          <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
          </set-header>
          <set-body>{
      "id": "P001",
      "name": "Laptop Pro",
      "category": "Electronics",
      "price": 1299.99,
      "in_stock": true,
      "description": "High-performance laptop with 16GB RAM and 512GB SSD, ideal for professionals.",
      "specs": {
        "processor": "Intel Core i7-1260P",
        "ram_gb": 16,
        "storage": "512GB NVMe SSD",
        "display": "15.6-inch FHD IPS",
        "battery_h": 12
      },
      "rating": {
        "average": 4.5,
        "count": 238
      }
    }</set-body>
        </return-response>
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}
