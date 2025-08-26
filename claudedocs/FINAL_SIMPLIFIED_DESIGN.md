# Final Simplified Design - Manual Token Management

## Overview

Based on clarifications and NinjaVanApi patterns:
1. **Manual token management** - Users handle token lifecycle themselves
2. **OpenStruct-based objects** - Use Base class extending OpenStruct for response encapsulation
3. **Faraday HTTP client** - Use Faraday gem for HTTP requests with proper configuration
4. **Only 5 endpoints needed**

## Architecture

```
Mintsoft Gem (Final Simplified)
├── Client (token-only initialization with Faraday)
├── Base (OpenStruct-based object for response encapsulation)
├── Resources
│   ├── Orders (search method only)
│   └── Returns (reasons, create, add_item methods only)
├── Objects (OpenStruct-based response objects)
│   ├── Order (extends Base)
│   ├── Return (extends Base with nested items)
│   └── ReturnReason (extends Base)
└── Support
    ├── BaseResource (common Faraday patterns)
    └── Errors (basic error classes)
```

## File Structure (Minimal)

```
lib/
├── mintsoft.rb                     # Main entry point
├── mintsoft/
│   ├── version.rb                  # Version constant
│   ├── client.rb                   # Token-only client with Faraday
│   ├── auth_client.rb              # Authentication client (Faraday-based)
│   ├── base.rb                     # Base OpenStruct object (like NinjaVanApi::Base)
│   ├── errors.rb                   # Basic error classes
│   ├── resources/
│   │   ├── base_resource.rb        # Base resource with Faraday patterns
│   │   ├── orders.rb               # Orders.search only
│   │   └── returns.rb              # Returns.reasons, create, add_item
│   └── objects/
│       ├── order.rb                # Order object extending Base
│       ├── return.rb               # Return object with nested items
│       └── return_reason.rb        # ReturnReason object extending Base
```

## Client Usage Pattern

### 1. User Gets Token (Outside Gem)
```ruby
# User's responsibility - not part of gem
def get_mintsoft_token(username, password)
  uri = URI('https://api.mintsoft.com/api/auth')
  
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = { username: username, password: password }.to_json
  
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  
  if response.code == '200'
    JSON.parse(response.body)['token']
  else
    raise "Authentication failed"
  end
end

token = get_mintsoft_token("username", "password")
```

### 2. Use Gem with Token (Faraday-based Client)
```ruby
# Initialize client with token (following NinjaVanApi pattern)
client = Mintsoft::Client.new(token: token)

# Complete workflow - responses are OpenStruct objects
orders = client.orders.search("ORD-2024-001")
order = orders.first

# Access properties through OpenStruct interface
puts order.order_number  # or order.order_ref
puts order.customer_id

reasons = client.returns.reasons
damage_reason = reasons.find { |r| r.name.include?("Damage") }

return_obj = client.returns.create(order.id)

# Add item - attributes passed as hash, converted to OpenStruct internally
client.returns.add_item(return_obj.id, {
  product_id: 123,
  quantity: 2,
  reason_id: damage_reason.id,
  unit_value: 25.00
})

# Access nested items as OpenStruct objects
return_obj.items.each do |item|
  puts "#{item.quantity} x #{item.product_name} - #{item.reason}"
end
```

## OpenStruct-Based Objects (Following NinjaVanApi Pattern)

### 1. Base Object (Core Pattern)
```ruby
# lib/mintsoft/base.rb
require "active_support"
require "active_support/core_ext/string"
require "ostruct"

module Mintsoft
  class Base < OpenStruct
    def initialize(attributes)
      super to_ostruct(attributes)
    end

    def to_ostruct(obj)
      if obj.is_a?(Hash)
        OpenStruct.new(obj.map { |key, val| [key.to_s.underscore, to_ostruct(val)] }.to_h)
      elsif obj.is_a?(Array)
        obj.map { |o| to_ostruct(o) }
      else # Assumed to be a primitive value
        obj
      end
    end

    # Convert back to hash without table key, including nested structures
    def to_hash
      ostruct_to_hash(self)
    end

    private

    def ostruct_to_hash(object)
      case object
      when OpenStruct
        hash = object.to_h.reject { |k, _| k == :table }
        hash.transform_values { |value| ostruct_to_hash(value) }
      when Array
        object.map { |item| ostruct_to_hash(item) }
      when Hash
        object.transform_values { |value| ostruct_to_hash(value) }
      else
        object
      end
    end
  end
end
```

### 2. Return Object (with nested items)
```ruby
# lib/mintsoft/objects/return.rb
module Mintsoft
  class Return < Base
    # Access nested items as OpenStruct objects
    def items
      return_items || items_array || []
    end
    
    def items_count
      items.length
    end
    
    # Access item properties through OpenStruct
    def item_quantities
      items.map(&:quantity).sum
    end
    
    # Convenience methods for common API response formats
    def return_id
      id || return_id
    end
  end
end
```

### 3. Order Object (basic)
```ruby
# lib/mintsoft/objects/order.rb
module Mintsoft
  class Order < Base
    # Convenience methods for common API response formats
    def order_id
      id || order_id
    end
    
    def order_ref
      order_number || order_reference || ref
    end
  end
end
```

### 4. ReturnReason Object (basic)
```ruby
# lib/mintsoft/objects/return_reason.rb
module Mintsoft
  class ReturnReason < Base
    def active?
      active == true
    end
  end
end
```

## Faraday-Based Client (Following NinjaVanApi Pattern)

### 1. Client Implementation
```ruby
# lib/mintsoft/client.rb
require "faraday"
require "faraday/net_http"

module Mintsoft
  class Client
    BASE_URL = "https://api.mintsoft.com".freeze
    
    attr_reader :token
    
    def initialize(token:, base_url: BASE_URL, conn_opts: {})
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
      @orders ||= OrderResource.new(self)
    end
    
    def returns
      @returns ||= ReturnResource.new(self)
    end
  end
end
```

### 2. Orders Resource (Faraday-based)
```ruby
# lib/mintsoft/resources/orders.rb
module Mintsoft
  class OrderResource
    def initialize(client)
      @client = client
    end
    
    def search(order_number)
      validate_order_number!(order_number)
      
      response = @client.connection.get('/api/Order/Search') do |req|
        req.params['OrderNumber'] = order_number
      end
      
      if response.success?
        parse_orders(response.body)
      else
        handle_error(response)
      end
    end
    
    private
    
    def validate_order_number!(order_number)
      raise Mintsoft::ValidationError, "Order number required" if order_number.nil? || order_number.empty?
    end
    
    def parse_orders(data)
      return [] unless data.is_a?(Array)
      data.map { |order_data| Mintsoft::Order.new(order_data) }
    end
    
    def handle_error(response)
      case response.status
      when 401
        raise Mintsoft::AuthenticationError, "Invalid or expired token"
      when 404
        [] # Return empty array for not found
      else
        raise Mintsoft::APIError, "API error: #{response.status} - #{response.body}"
      end
    end
  end
end
```

### 3. Returns Resource (Faraday-based)
```ruby
# lib/mintsoft/resources/returns.rb
module Mintsoft
  class ReturnResource
    def initialize(client)
      @client = client
    end
    
    def reasons
      response = @client.connection.get('/api/Return/Reasons')
      
      if response.success?
        parse_reasons(response.body)
      else
        handle_error(response)
      end
    end
    
    def create(order_id)
      validate_order_id!(order_id)
      
      response = @client.connection.post("/api/Return/CreateReturn/#{order_id}")
      
      if response.success?
        # Extract return ID from ToolkitResult and create Return object
        return_id = extract_return_id(response.body)
        Mintsoft::Return.new({'id' => return_id, 'order_id' => order_id, 'status' => 'pending'})
      else
        handle_error(response)
      end
    end
    
    def add_item(return_id, item_attributes)
      validate_return_id!(return_id)
      validate_item_attributes!(item_attributes)
      
      payload = format_item_payload(item_attributes)
      response = @client.connection.post("/api/Return/#{return_id}/AddItem") do |req|
        req.body = payload
      end
      
      if response.success?
        true # Simple success indicator
      else
        handle_error(response)
      end
    end
    
    private
    
    def validate_order_id!(order_id)
      raise Mintsoft::ValidationError, "Order ID required" unless order_id&.to_i&.positive?
    end
    
    def validate_return_id!(return_id)
      raise Mintsoft::ValidationError, "Return ID required" unless return_id&.to_i&.positive?
    end
    
    def validate_item_attributes!(attrs)
      required = [:product_id, :quantity, :reason_id]
      required.each do |field|
        raise Mintsoft::ValidationError, "#{field} required" unless attrs[field]
      end
      raise Mintsoft::ValidationError, "Quantity must be positive" unless attrs[:quantity].to_i > 0
    end
    
    def parse_reasons(data)
      return [] unless data.is_a?(Array)
      data.map { |reason_data| Mintsoft::ReturnReason.new(reason_data) }
    end
    
    def extract_return_id(toolkit_result)
      # Parse ToolkitResult to extract return ID - handles various response formats
      toolkit_result.dig('result', 'return_id') || 
      toolkit_result.dig('data', 'id') ||
      toolkit_result['id']
    end
    
    def format_item_payload(attrs)
      {
        'ProductId' => attrs[:product_id],
        'Quantity' => attrs[:quantity],
        'ReasonId' => attrs[:reason_id],
        'UnitValue' => attrs[:unit_value],
        'Notes' => attrs[:notes]
      }.compact
    end
    
    def handle_error(response)
      case response.status
      when 401
        raise Mintsoft::AuthenticationError, "Invalid or expired token"
      when 400
        raise Mintsoft::ValidationError, "Invalid request data: #{response.body}"
      when 404
        raise Mintsoft::NotFoundError, "Resource not found"
      else
        raise Mintsoft::APIError, "API error: #{response.status} - #{response.body}"
      end
    end
  end
end
```

## Complete Usage Example

### Token Management Class (User's Code)
```ruby
class MintsoftTokenManager
  def initialize(username, password)
    @username = username
    @password = password
    @token = nil
    @expires_at = nil
  end
  
  def get_valid_token
    if token_expired?
      refresh_token
    end
    @token
  end
  
  def client
    Mintsoft::Client.new(token: get_valid_token)
  end
  
  private
  
  def token_expired?
    @token.nil? || @expires_at.nil? || Time.now >= @expires_at
  end
  
  def refresh_token
    @token = fetch_token(@username, @password)
    @expires_at = Time.now + 23.hours # Buffer before 24h expiry
  end
  
  def fetch_token(username, password)
    # User's authentication implementation
    uri = URI('https://api.mintsoft.com/api/auth')
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = { username: username, password: password }.to_json
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    if response.code == '200'
      JSON.parse(response.body)['token']
    else
      raise "Authentication failed: #{response.body}"
    end
  end
end
```

### Complete Workflow (with OpenStruct Objects and Faraday)
```ruby
# Initialize token manager
token_manager = MintsoftTokenManager.new(
  ENV['MINTSOFT_USERNAME'], 
  ENV['MINTSOFT_PASSWORD']
)

begin
  client = token_manager.client
  
  # 1. Search for order - returns array of OpenStruct-based Order objects
  orders = client.orders.search("ORD-2024-001")
  order = orders.first
  raise "Order not found" unless order
  
  # Access order properties through OpenStruct interface
  puts "Found order: #{order.order_number} (ID: #{order.id})"
  puts "Customer: #{order.customer_id}, Status: #{order.status}"
  
  # 2. Get return reasons - returns array of OpenStruct-based ReturnReason objects
  reasons = client.returns.reasons
  damage_reason = reasons.find { |r| r.name.include?("Damage") && r.active? }
  
  puts "Using reason: #{damage_reason.name} (#{damage_reason.description})"
  
  # 3. Create return - returns OpenStruct-based Return object
  return_obj = client.returns.create(order.id)
  puts "Created return: #{return_obj.id} for order: #{return_obj.order_id}"
  
  # 4. Add item to return - item data converted to OpenStruct internally
  success = client.returns.add_item(return_obj.id, {
    product_id: 123,
    quantity: 2,
    reason_id: damage_reason.id,
    unit_value: 25.00,
    notes: "Damaged in shipping"
  })
  
  if success
    puts "Return created successfully!"
    
    # Refetch return to see nested items (if API provides them)
    # Items would be accessible as OpenStruct objects:
    # return_obj.items.each do |item|
    #   puts "Item: #{item.product_id}, Qty: #{item.quantity}, Reason: #{item.reason_name}"
    # end
  end
  
rescue Mintsoft::AuthenticationError
  puts "Token expired or invalid - will retry with new token"
  token_manager.refresh_token
  retry
rescue Mintsoft::ValidationError => e
  puts "Validation Error: #{e.message}"
rescue Mintsoft::APIError => e
  puts "API Error: #{e.message}"
end
```

## Key Simplifications (Updated Design)

### Removed Components
- ❌ `ReturnItem` object (items are nested OpenStruct objects in Return)
- ❌ `Authentication` class (manual token management)
- ❌ `TokenStorage` utilities (user handles storage)
- ❌ Automatic token renewal logic
- ❌ Configuration management
- ❌ Custom HTTP client implementation

### New Components (Following NinjaVanApi Patterns)
- ✅ **Base class** extending OpenStruct for response encapsulation
- ✅ **Faraday-based client** with proper configuration and middleware
- ✅ **OpenStruct objects** for flexible attribute access
- ✅ **Automatic attribute conversion** (camelCase ↔ snake_case)
- ✅ **Nested object support** with recursive OpenStruct conversion

### Simplified Components  
- ✅ Token-only client initialization with Faraday
- ✅ OpenStruct-based response objects (Order, Return, ReturnReason)
- ✅ Return object with nested items as OpenStruct objects
- ✅ Faraday middleware for JSON handling and authorization
- ✅ Flexible attribute access (both API format and Ruby conventions)

### Benefits of New Design
- **Familiar Patterns**: Follows proven NinjaVanApi architecture
- **Flexible Access**: OpenStruct allows both `object.field` and `object['field']` access
- **Automatic Conversion**: API responses automatically converted to Ruby conventions
- **Robust HTTP**: Faraday provides connection pooling, middleware, and better error handling
- **Nested Support**: Complex API responses with nested objects handled seamlessly
- **Maintainable**: Less custom code, leveraging battle-tested gems

This design maintains simplicity while providing more robust foundations using proven patterns from similar API wrapper gems.