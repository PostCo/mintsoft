# Minimal Implementation Plan

## Scope Clarification

Based on your requirements, we need exactly these 5 endpoints:

1. `POST /api/auth` - Authentication
2. `GET /api/Order/Search` - Search orders by order number  
3. `GET /api/Return/Reasons` - Get return reasons
4. `POST /api/Return/CreateReturn/{OrderId}` - Create return for order
5. `POST /api/Return/{id}/AddItem` - Add item to return

## Implementation Order

### Step 1: AuthClient for Token Management (Day 1-2)
```ruby
# lib/mintsoft/auth_client.rb
class AuthClient
  def initialize(base_url: BASE_URL)
  def connection # Faraday connection
  def auth # Auth resource
end

# Usage
auth_client = AuthClient.new
token = auth_client.auth.authenticate("user", "pass")
```

### Step 2: Faraday Client Setup (Day 1-2)
```ruby
# lib/mintsoft/client.rb
require "faraday"
require "faraday/net_http"

class Client
  BASE_URL = "https://api.mintsoft.com".freeze
  
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
    @orders ||= Resources::Orders.new(self)
  end
  
  def returns  
    @returns ||= Resources::Returns.new(self)
  end
end
```

### Step 3: BaseResource Pattern (Day 2-3)
```ruby
# lib/mintsoft/resources/base_resource.rb
class BaseResource
  def initialize(client)
  def get_request(url, params: {})
  def post_request(url, body: {})
  def handle_response(response)
end

# Usage
client = Client.new(token: "api_token")
```

### Step 4: Orders Resource (Day 3-4)
```ruby
# lib/mintsoft/resources/orders.rb
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

# lib/mintsoft/objects/order.rb
class Order < Base
  def order_id
    id || order_id
  end
  
  def order_ref
    order_number || order_reference || ref
  end
end
```

### Step 5: Returns Resource (Day 4-6)
```ruby
# lib/mintsoft/resources/returns.rb
class Returns
  def reasons
    # GET /api/Return/Reasons
    # Returns array of ReturnReason objects
  end
  
  def create(order_id)
    # POST /api/Return/CreateReturn/{OrderId}
    # Returns Return object
  end
  
  def add_item(return_id, item_attributes)
    # POST /api/Return/{id}/AddItem
    # Returns success/failure
  end
end

# Objects
class Return
  attr_reader :id, :order_id, :status
end

class ReturnReason  
  attr_reader :id, :name, :description
end
```

### Step 6: Error Handling (Day 6-7)
```ruby
# lib/mintsoft/errors.rb
class Error < StandardError; end
class APIError < Error; end
class AuthenticationError < APIError; end
class NotFoundError < APIError; end
class ValidationError < APIError; end
```

### Step 7: BaseResource Pattern (Day 7)
```ruby
# lib/mintsoft/resources/base_resource.rb
class BaseResource
  def initialize(client)
  def get_request(url, params: {})
  def post_request(url, body: {})
  def handle_response(response)
end
```

## Complete Usage Flow

```ruby
require 'mintsoft'

# Step 1: Get token using AuthClient  
auth_client = Mintsoft::AuthClient.new
token = auth_client.auth.authenticate(
  ENV['MINTSOFT_USERNAME'],
  ENV['MINTSOFT_PASSWORD']
)

# Step 2: Initialize client with token
client = Mintsoft::Client.new(token: token)

# 1. Search for order
orders = client.orders.search("ORD-2024-001")
order = orders.first
raise "Order not found" unless order

puts "Found order: #{order.order_number} (ID: #{order.id})"

# 2. Get available return reasons
reasons = client.returns.reasons
puts "Available reasons: #{reasons.map(&:name).join(', ')}"

# Select a reason (e.g., first one or by name)
selected_reason = reasons.first

# 3. Create return for the order
return_obj = client.returns.create(order.id)
puts "Created return ID: #{return_obj.id}"

# 4. Add item to the return
result = client.returns.add_item(return_obj.id, {
  product_id: 123,           # Product ID from order
  quantity: 2,               # Quantity to return
  reason_id: selected_reason.id,
  unit_value: 25.00,         # Unit value
  notes: "Damaged in shipping"
})

puts "Item added to return successfully" if result.success?
```

## File Creation Checklist

### Core Files
- [ ] `lib/mintsoft.rb` - Main entry point
- [ ] `lib/mintsoft/version.rb` - Version constant  
- [ ] `lib/mintsoft/client.rb` - Main client class (Faraday-based)
- [ ] `lib/mintsoft/auth_client.rb` - Authentication client
- [ ] `lib/mintsoft/base.rb` - Base OpenStruct object
- [ ] `lib/mintsoft/errors.rb` - Error classes

### Resource Files  
- [ ] `lib/mintsoft/resources/base_resource.rb` - Base resource pattern
- [ ] `lib/mintsoft/resources/orders.rb` - Orders search
- [ ] `lib/mintsoft/resources/returns.rb` - Returns operations

### Object Files
- [ ] `lib/mintsoft/objects/order.rb` - Order object
- [ ] `lib/mintsoft/objects/return.rb` - Return object  
- [ ] `lib/mintsoft/objects/return_reason.rb` - Return reason object

### Test Files
- [ ] `spec/mintsoft/client_spec.rb`
- [ ] `spec/mintsoft/resources/orders_spec.rb`
- [ ] `spec/mintsoft/resources/returns_spec.rb`
- [ ] `spec/integration/workflow_spec.rb`

## Gemspec Updates

Add required dependencies:
```ruby
# mintsoft.gemspec
spec.add_dependency "faraday", "~> 2.0"
spec.add_dependency "faraday-net_http", "~> 3.0"
spec.add_dependency "active_support", "~> 7.0"

spec.add_development_dependency "rspec", "~> 3.0"
spec.add_development_dependency "vcr", "~> 6.0" 
spec.add_development_dependency "webmock", "~> 3.0"
```

## Testing Approach

### Unit Tests (Mock HTTP responses)
```ruby
# spec/mintsoft/resources/orders_spec.rb
RSpec.describe Mintsoft::Orders do
  it "searches for orders by order number" do
    # Mock HTTP response
    # Test order parsing
  end
end
```

### Integration Tests (VCR cassettes)
```ruby  
# spec/integration/workflow_spec.rb
RSpec.describe "Complete workflow", :vcr do
  it "completes order to return workflow" do
    client = Mintsoft::Client.new(username: "test", password: "test")
    
    # Test real API flow with recorded responses
    orders = client.orders.search("TEST-ORDER")
    # ... rest of workflow
  end
end
```

## Error Scenarios to Handle

1. **Authentication failures** (401)
2. **Order not found** (404)  
3. **Invalid order number** (400)
4. **Network timeouts**
5. **Server errors** (500)
6. **Token expiration** (automatic renewal)

## Validation Rules

### Orders.search
- Order number cannot be empty
- Order number max length validation

### Returns.create  
- Order ID must be positive integer

### Returns.add_item
- Return ID required
- Product ID required
- Quantity must be positive
- Reason ID required
- Unit value cannot be negative

## Success Criteria

- [ ] All 5 endpoints implemented and working
- [ ] Complete workflow from order search to return item addition
- [ ] Automatic authentication token management
- [ ] Proper error handling for common scenarios
- [ ] Unit tests for all components
- [ ] Integration test for complete workflow
- [ ] Documentation with usage examples

This minimal plan focuses only on the required functionality and provides a clear path to implementation in about 1 week.