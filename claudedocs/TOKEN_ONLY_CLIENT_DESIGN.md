# Token-Only Client Design

## Overview

The Mintsoft client is extremely simplified - it only accepts a pre-obtained API token on initialization. All token management (obtaining, storing, renewal) is the user's responsibility outside the gem.

## Client Interface

### Initialization
```ruby
# Only way to initialize client
client = Mintsoft::Client.new(token: "your_api_token_here")

# Optional base URL override
client = Mintsoft::Client.new(
  token: "your_api_token_here",
  base_url: "https://custom.mintsoft.com/api"
)
```

### No Token Management Methods
```ruby
# Client does NOT provide these methods:
# client.authenticate(username, password)
# client.refresh_token
# client.token_valid?
# client.get_token
# client.set_credentials(username, password)
```

## Implementation

### 1. Simplified Client Class (Faraday-based)
```ruby
# lib/mintsoft/client.rb
require "faraday"
require "faraday/net_http"

module Mintsoft
  class Client
    BASE_URL = "https://api.mintsoft.com".freeze
    
    attr_reader :token
    
    def initialize(token:, base_url: BASE_URL, conn_opts: {})
      raise ArgumentError, "Token is required" if token.nil? || token.empty?
      
      @token = token
      @base_url = base_url
      @conn_opts = conn_opts
    end
    
    def connection
      @connection ||= Faraday.new do |conn|
        conn.url_prefix = @base_url
        conn.options.merge!(@conn_opts)
        conn.request :authorization, :Bearer, @token
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end
    
    def orders
      @orders ||= Resources::Orders.new(self)
    end
    
    def returns
      @returns ||= Resources::Returns.new(self)
    end
  end
end
```

### 2. Resources Use BaseResource Pattern
```ruby
# lib/mintsoft/resources/base_resource.rb
module Mintsoft
  class BaseResource
    attr_reader :client
    
    def initialize(client)
      @client = client
    end
    
    protected
    
    def get_request(url, params: {}, headers: {})
      handle_response client.connection.get(url, params, headers)
    end
    
    def post_request(url, body: {}, headers: {})
      handle_response client.connection.post(url, body, headers)
    end
    
    private
    
    def handle_response(response)
      case response.status
      when 400
        raise ValidationError, "Invalid request: #{response.body}"
      when 401
        raise AuthenticationError, "Invalid or expired token"
      when 403
        raise AuthenticationError, "Access denied"
      when 404
        raise NotFoundError, "Resource not found"
      when 500
        raise APIError, "Internal server error"
      else
        response
      end
    end
  end
end
```

### 3. Orders Resource Example
```ruby
# lib/mintsoft/resources/orders.rb
module Mintsoft
  class OrderResource < BaseResource
    def search(order_number)
      validate_order_number!(order_number)
      
      response = get_request('/api/Order/Search', params: { OrderNumber: order_number })
      
      if response.success?
        parse_orders(response.body)
      else
        []
      end
    end
    
    private
    
    def validate_order_number!(order_number)
      raise ValidationError, "Order number required" if order_number.nil? || order_number.empty?
    end
    
    def parse_orders(data)
      return [] unless data.is_a?(Array)
      data.map { |order_data| Order.new(order_data) }
    end
  end
end
```

## User Token Management Examples

### Example 1: Using AuthClient (Recommended)
```ruby
# Initialize auth client
auth_client = Mintsoft::AuthClient.new

# Get token directly as string
token = auth_client.auth.authenticate(
  ENV['MINTSOFT_USERNAME'], 
  ENV['MINTSOFT_PASSWORD']
)

# Use token with main client
client = Mintsoft::Client.new(token: token)

puts "Token obtained: #{token[0..7]}...#{token[-4..-1]}" # Show first 8 + last 4 chars for security
```

### Example 2: Token with Caching
```ruby
class TokenManager
  def initialize(username, password)
    @username = username
    @password = password
    @auth_client = Mintsoft::AuthClient.new
    @token = nil
    @token_expires_at = nil
  end
  
  def current_token
    if token_expired?
      refresh_token!
    end
    @token
  end
  
  def client
    Mintsoft::Client.new(token: current_token)
  end
  
  def token_info
    {
      token: @token ? "#{@token[0..7]}...#{@token[-4..-1]}" : nil,
      expires_at: @token_expires_at,
      expired: token_expired?
    }
  end
  
  private
  
  def token_expired?
    @token.nil? || @token_expires_at.nil? || Time.now >= @token_expires_at
  end
  
  def refresh_token!
    @token = @auth_client.auth.authenticate(@username, @password)
    @token_expires_at = Time.now + 23.hours # 23 hours to be safe (Mintsoft tokens typically last 24h)
  end
end

# Usage
token_manager = TokenManager.new('username', 'password')
client = token_manager.client
puts "Token info: #{token_manager.token_info}"
```

### Example 3: Token with Redis Storage
```ruby
class RedisTokenManager
  def initialize(username, password, redis_client)
    @username = username
    @password = password
    @redis = redis_client
    @token_key = "mintsoft:token:#{username}"
  end
  
  def current_token
    token = @redis.get(@token_key)
    
    if token.nil?
      token = fetch_and_store_token
    end
    
    token
  end
  
  def client
    Mintsoft::Client.new(token: current_token)
  end
  
  private
  
  def fetch_and_store_token
    token = get_mintsoft_token(@username, @password)
    
    # Store with 23 hour expiry (1 hour buffer)
    @redis.setex(@token_key, 23.hours.to_i, token)
    
    token
  end
end

# Usage
redis = Redis.new(url: ENV['REDIS_URL'])
token_manager = RedisTokenManager.new('username', 'password', redis)
client = token_manager.client
```

### Example 4: Error Handling with Retry
```ruby
class RobustTokenManager
  def initialize(username, password)
    @username = username
    @password = password
    @token = nil
    @token_expires_at = nil
  end
  
  def execute_with_client(&block)
    client = Mintsoft::Client.new(token: current_token)
    
    begin
      block.call(client)
    rescue Mintsoft::AuthenticationError => e
      if e.status_code == 401
        # Token expired, refresh and retry once
        invalidate_token!
        client = Mintsoft::Client.new(token: current_token)
        block.call(client)
      else
        raise e
      end
    end
  end
  
  private
  
  def current_token
    if token_expired?
      refresh_token!
    end
    @token
  end
  
  def invalidate_token!
    @token = nil
    @token_expires_at = nil
  end
  
  def token_expired?
    @token.nil? || @token_expires_at.nil? || Time.now >= @token_expires_at
  end
  
  def refresh_token!
    @token = get_mintsoft_token(@username, @password)
    @token_expires_at = Time.now + 23.hours
  end
end

# Usage
token_manager = RobustTokenManager.new('username', 'password')

result = token_manager.execute_with_client do |client|
  orders = client.orders.search("ORD-2024-001")
  # ... rest of workflow
  orders
end
```

## Complete Workflow Example

```ruby
# Step 1: Get token using AuthClient
auth_client = Mintsoft::AuthClient.new
auth_response = auth_client.auth.authenticate(
  ENV['MINTSOFT_USERNAME'], 
  ENV['MINTSOFT_PASSWORD']
)

# Step 2: Use token with main client
client = Mintsoft::Client.new(token: auth_response.token)

begin
  # 1. Search order
  orders = client.orders.search("ORD-2024-001")
  order = orders.first
  raise "Order not found" unless order
  
  # 2. Get return reasons
  reasons = client.returns.reasons
  damage_reason = reasons.first
  
  # 3. Create return
  return_obj = client.returns.create(order.id)
  
  # 4. Add item
  client.returns.add_item(return_obj.id, {
    product_id: 123,
    quantity: 2,
    reason_id: damage_reason.id,
    unit_value: 25.00
  })
  
  puts "Return created successfully!"
  
rescue Mintsoft::AuthenticationError => e
  if e.status_code == 401
    puts "Token expired or invalid - please obtain new token"
    # User must handle token renewal and retry
  end
rescue Mintsoft::APIError => e
  puts "API Error: #{e.message}"
end
```

## File Structure (Final)

```
lib/
├── mintsoft.rb                    # Main entry point
├── mintsoft/
│   ├── version.rb                 # Version constant
│   ├── client.rb                  # Main API client (Faraday-based, token-only)
│   ├── auth_client.rb             # Authentication client (Faraday-based)
│   ├── base.rb                    # Base OpenStruct object
│   ├── errors.rb                  # Error classes
│   ├── resources/
│   │   ├── base_resource.rb       # Base resource with common Faraday patterns
│   │   ├── auth.rb                # Auth resource (POST /api/auth)
│   │   ├── orders.rb              # Orders.search
│   │   └── returns.rb             # Returns.reasons, create, add_item
│   └── objects/
│       ├── order.rb               # Order object
│       ├── return.rb              # Return with nested items
│       └── return_reason.rb       # ReturnReason object
```

## Key Benefits

### 1. **Extreme Simplicity**
- Client only needs token parameter
- No authentication logic in gem
- Minimal surface area for bugs

### 2. **User Control**
- User decides token storage strategy
- User handles token expiration as needed
- User controls when to refresh tokens

### 3. **Security**
- No credential handling in gem
- User controls sensitive data
- Clear separation of concerns

### 4. **Flexibility**  
- Works with any token management strategy
- Easy to integrate with existing auth systems
- Supports different storage backends (Redis, database, etc.)

This design makes the gem as simple as possible while giving users complete control over authentication and token management.