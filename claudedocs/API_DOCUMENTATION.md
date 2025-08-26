# Mintsoft API Documentation

## Overview
This document outlines the planned API structure for the Mintsoft gem. The gem will provide a Ruby interface to interact with the Mintsoft platform API.

## Installation & Configuration

### Installation
```ruby
# Add to Gemfile
gem 'mintsoft', '~> 0.1.0'

# Or install directly
gem install mintsoft
```

### Configuration
```ruby
require 'mintsoft'

Mintsoft.configure do |config|
  config.api_key = ENV['MINTSOFT_API_KEY']
  config.api_url = 'https://api.mintsoft.com/v1'
  config.timeout = 30
end
```

## Client Usage

### Basic Client
```ruby
# Initialize client
client = Mintsoft::Client.new

# Or with custom configuration
client = Mintsoft::Client.new(
  api_key: 'your_key',
  api_url: 'custom_endpoint'
)
```

## Planned API Resources

### Orders Management
```ruby
# List orders
orders = client.orders.list
orders = client.orders.list(status: 'pending', limit: 50)

# Get specific order
order = client.orders.get(order_id)

# Create order
order = client.orders.create({
  customer_id: 123,
  items: [
    { sku: 'PRODUCT-001', quantity: 2 },
    { sku: 'PRODUCT-002', quantity: 1 }
  ]
})

# Update order
order = client.orders.update(order_id, { status: 'processing' })

# Cancel order
client.orders.cancel(order_id)
```

### Products Management
```ruby
# List products
products = client.products.list
products = client.products.list(category: 'electronics', active: true)

# Get specific product
product = client.products.get(product_id)

# Create product
product = client.products.create({
  name: 'Example Product',
  sku: 'EXAMPLE-001',
  price: 29.99,
  category: 'electronics'
})

# Update product
product = client.products.update(product_id, { price: 24.99 })

# Delete product
client.products.delete(product_id)
```

### Inventory Management
```ruby
# Get inventory levels
inventory = client.inventory.list
inventory = client.inventory.get(product_id)

# Update inventory
client.inventory.update(product_id, { quantity: 100 })

# Inventory movements
movements = client.inventory.movements(product_id)
```

### Customers Management
```ruby
# List customers
customers = client.customers.list

# Get customer
customer = client.customers.get(customer_id)

# Create customer
customer = client.customers.create({
  name: 'John Doe',
  email: 'john@example.com',
  phone: '+1234567890'
})
```

## Response Format

### Successful Response
```ruby
# All API calls return response objects
response = client.orders.list
response.success?        # => true
response.data           # => Array or Hash of data
response.status_code    # => 200
response.headers        # => Response headers hash
```

### Error Handling
```ruby
begin
  order = client.orders.get(invalid_id)
rescue Mintsoft::APIError => e
  puts "API Error: #{e.message}"
  puts "Status Code: #{e.status_code}"
  puts "Response Body: #{e.response_body}"
rescue Mintsoft::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Mintsoft::Error => e
  puts "General error: #{e.message}"
end
```

## Error Classes

```ruby
module Mintsoft
  class Error < StandardError; end
  
  class APIError < Error
    attr_reader :status_code, :response_body
    
    def initialize(message, status_code: nil, response_body: nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
    end
  end
  
  class AuthenticationError < APIError; end
  class NotFoundError < APIError; end
  class RateLimitError < APIError; end
  class ValidationError < APIError; end
end
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `api_key` | `nil` | Mintsoft API authentication key |
| `api_url` | `'https://api.mintsoft.com/v1'` | Base API URL |
| `timeout` | `30` | Request timeout in seconds |
| `retry_attempts` | `3` | Number of retry attempts for failed requests |
| `retry_delay` | `1` | Delay between retry attempts (seconds) |
| `user_agent` | `"Mintsoft Ruby Gem v#{VERSION}"` | User agent string |

## Advanced Usage

### Custom Headers
```ruby
client = Mintsoft::Client.new do |config|
  config.default_headers = {
    'X-Custom-Header' => 'value',
    'X-Request-ID' => SecureRandom.uuid
  }
end
```

### Request Logging
```ruby
Mintsoft.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.log_level = :debug
end
```

### Pagination
```ruby
# Handle paginated responses
orders = client.orders.list(page: 1, per_page: 25)

# Iterate through all pages
client.orders.each do |order|
  puts order.id
end
```

## Testing

### VCR Integration
```ruby
# spec/spec_helper.rb
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<API_KEY>') { ENV['MINTSOFT_API_KEY'] }
end
```

### Mock Client
```ruby
# For testing without API calls
client = Mintsoft::Client.new(mock: true)
```

## Implementation Status

- [ ] Base Client class
- [ ] Authentication handling
- [ ] Error classes and handling
- [ ] Orders resource
- [ ] Products resource  
- [ ] Inventory resource
- [ ] Customers resource
- [ ] Response wrapper classes
- [ ] Configuration management
- [ ] Logging support
- [ ] Retry logic
- [ ] Pagination support
- [ ] Rate limiting
- [ ] Test suite with VCR
- [ ] Documentation examples

## Contributing

See [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) for development setup and contribution guidelines.