# Mintsoft Gem Usage Examples

## Overview

This document provides complete usage examples for the Mintsoft gem, showing how to use the AuthClient for token management and the main Client for API operations.

## Basic Usage

### Step 1: Authentication
```ruby
require 'mintsoft'

# Initialize auth client
auth_client = Mintsoft::AuthClient.new

# Get authentication token
auth_response = auth_client.auth.authenticate(
  ENV['MINTSOFT_USERNAME'], 
  ENV['MINTSOFT_PASSWORD']
)

# Check token validity
puts "Token: #{auth_response.token}"
puts "Expires at: #{auth_response.expires_at}"
puts "Valid: #{auth_response.valid?}"
```

### Step 2: API Operations
```ruby
# Initialize main client with token
client = Mintsoft::Client.new(token: auth_response.token)

# Search for orders
orders = client.orders.search("ORD-2024-001")
puts "Found #{orders.length} orders"

# Get return reasons
reasons = client.returns.reasons
puts "Available reasons: #{reasons.map(&:name).join(', ')}"
```

## Complete Order-to-Return Workflow

```ruby
require 'mintsoft'

def complete_return_workflow(order_number, items_to_return)
  # Step 1: Authenticate and get token
  auth_client = Mintsoft::AuthClient.new
  
  begin
    auth_response = auth_client.auth.authenticate(
      ENV['MINTSOFT_USERNAME'], 
      ENV['MINTSOFT_PASSWORD']
    )
    
    unless auth_response.valid?
      puts "Invalid authentication response"
      return false
    end
    
    # Step 2: Initialize API client
    client = Mintsoft::Client.new(token: auth_response.token)
    
    # Step 3: Search for order
    puts "Searching for order: #{order_number}"
    orders = client.orders.search(order_number)
    
    if orders.empty?
      puts "Order not found: #{order_number}"
      return false
    end
    
    order = orders.first
    puts "Found order: #{order.order_number} (ID: #{order.id})"
    
    # Step 4: Get return reasons
    puts "Fetching return reasons..."
    reasons = client.returns.reasons
    
    if reasons.empty?
      puts "No return reasons available"
      return false
    end
    
    # Select first active reason (or find by name)
    selected_reason = reasons.find(&:active?) || reasons.first
    puts "Selected reason: #{selected_reason.name} (ID: #{selected_reason.id})"
    
    # Step 5: Create return
    puts "Creating return for order ID: #{order.id}"
    return_obj = client.returns.create(order.id)
    puts "Created return ID: #{return_obj.id}"
    
    # Step 6: Add items to return
    items_to_return.each_with_index do |item, index|
      puts "Adding item #{index + 1}: Product ID #{item[:product_id]}, Quantity #{item[:quantity]}"
      
      success = client.returns.add_item(return_obj.id, {
        product_id: item[:product_id],
        quantity: item[:quantity],
        reason_id: selected_reason.id,
        unit_value: item[:unit_value],
        notes: item[:notes]
      })
      
      if success
        puts "  ✓ Item added successfully"
      else
        puts "  ✗ Failed to add item"
        return false
      end
    end
    
    puts "Return workflow completed successfully!"
    puts "Return ID: #{return_obj.id}"
    return true
    
  rescue Mintsoft::AuthenticationError => e
    puts "Authentication failed: #{e.message}"
    return false
  rescue Mintsoft::ValidationError => e
    puts "Validation error: #{e.message}"
    return false
  rescue Mintsoft::NotFoundError => e
    puts "Resource not found: #{e.message}"
    return false
  rescue Mintsoft::APIError => e
    puts "API error: #{e.message}"
    return false
  end
end

# Usage
items = [
  {
    product_id: 123,
    quantity: 2,
    unit_value: 25.00,
    notes: "Damaged during shipping"
  },
  {
    product_id: 456,
    quantity: 1,
    unit_value: 50.00,
    notes: "Wrong item sent"
  }
]

success = complete_return_workflow("ORD-2024-001", items)
puts success ? "Workflow completed!" : "Workflow failed!"
```

## Token Management Patterns

### Pattern 1: Simple One-Time Use
```ruby
# For scripts or one-off operations
auth_client = Mintsoft::AuthClient.new
auth_response = auth_client.auth.authenticate("username", "password")

client = Mintsoft::Client.new(token: auth_response.token)
# Perform operations...
```

### Pattern 2: Cached Token Manager
```ruby
class MintsoftService
  def initialize(username, password)
    @username = username
    @password = password
    @auth_client = Mintsoft::AuthClient.new
    @auth_response = nil
  end
  
  def client
    ensure_valid_token!
    Mintsoft::Client.new(token: @auth_response.token)
  end
  
  def token_info
    @auth_response&.to_h
  end
  
  private
  
  def ensure_valid_token!
    if @auth_response.nil? || @auth_response.expired?
      refresh_token!
    end
  end
  
  def refresh_token!
    puts "Refreshing authentication token..."
    @auth_response = @auth_client.auth.authenticate(@username, @password)
    puts "Token refreshed, expires at: #{@auth_response.expires_at}"
  end
end

# Usage
service = MintsoftService.new(ENV['MINTSOFT_USERNAME'], ENV['MINTSOFT_PASSWORD'])

# Token is automatically managed
client = service.client
orders = client.orders.search("ORD-001")

# Check token status
puts service.token_info
```

### Pattern 3: Thread-Safe Token Manager
```ruby
require 'thread'

class ThreadSafeTokenManager
  def initialize(username, password)
    @username = username
    @password = password
    @auth_client = Mintsoft::AuthClient.new
    @auth_response = nil
    @mutex = Mutex.new
  end
  
  def client
    token = current_token
    Mintsoft::Client.new(token: token)
  end
  
  private
  
  def current_token
    @mutex.synchronize do
      if @auth_response.nil? || @auth_response.expired?
        @auth_response = @auth_client.auth.authenticate(@username, @password)
      end
      @auth_response.token
    end
  end
end

# Usage in multi-threaded environment
token_manager = ThreadSafeTokenManager.new("username", "password")

# Safe to use across multiple threads
threads = 3.times.map do |i|
  Thread.new do
    client = token_manager.client
    orders = client.orders.search("ORD-00#{i}")
    puts "Thread #{i}: Found #{orders.length} orders"
  end
end

threads.each(&:join)
```

### Pattern 4: Persistent Token Storage
```ruby
require 'json'
require 'fileutils'

class PersistentTokenManager
  TOKEN_FILE = '.mintsoft_token'
  
  def initialize(username, password)
    @username = username
    @password = password
    @auth_client = Mintsoft::AuthClient.new
  end
  
  def client
    token = current_token
    Mintsoft::Client.new(token: token)
  end
  
  def clear_stored_token
    File.delete(TOKEN_FILE) if File.exist?(TOKEN_FILE)
  end
  
  private
  
  def current_token
    stored_token = load_stored_token
    
    if stored_token && !token_expired?(stored_token)
      return stored_token['token']
    end
    
    # Get fresh token and store it
    auth_response = @auth_client.auth.authenticate(@username, @password)
    store_token(auth_response)
    auth_response.token
  end
  
  def load_stored_token
    return nil unless File.exist?(TOKEN_FILE)
    
    begin
      JSON.parse(File.read(TOKEN_FILE))
    rescue JSON::ParserError
      nil
    end
  end
  
  def store_token(auth_response)
    token_data = {
      'token' => auth_response.token,
      'expires_at' => auth_response.expires_at.to_i,
      'created_at' => Time.now.to_i
    }
    
    File.write(TOKEN_FILE, JSON.pretty_generate(token_data))
  end
  
  def token_expired?(stored_token)
    expires_at = Time.at(stored_token['expires_at'])
    Time.now >= expires_at
  end
end

# Usage
token_manager = PersistentTokenManager.new("username", "password")

# Token persists across script runs
client = token_manager.client

# Clear stored token if needed
# token_manager.clear_stored_token
```

## Error Handling Patterns

### Pattern 1: Basic Error Handling
```ruby
begin
  auth_client = Mintsoft::AuthClient.new
  auth_response = auth_client.auth.authenticate("username", "password")
  
  client = Mintsoft::Client.new(token: auth_response.token)
  orders = client.orders.search("ORD-001")
  
  puts "Found #{orders.length} orders"
  
rescue Mintsoft::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Mintsoft::ValidationError => e
  puts "Invalid input: #{e.message}"
rescue Mintsoft::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue Mintsoft::APIError => e
  puts "API error (#{e.status_code}): #{e.message}"
rescue Mintsoft::Error => e
  puts "Mintsoft error: #{e.message}"
end
```

### Pattern 2: Retry Logic
```ruby
def with_retry(max_attempts: 3, delay: 1)
  attempt = 1
  
  begin
    yield
  rescue Mintsoft::APIError => e
    if e.status_code == 500 && attempt < max_attempts
      puts "Server error, retrying in #{delay} seconds... (attempt #{attempt}/#{max_attempts})"
      sleep(delay)
      attempt += 1
      retry
    else
      raise e
    end
  end
end

# Usage
with_retry(max_attempts: 3, delay: 2) do
  client = Mintsoft::Client.new(token: token)
  orders = client.orders.search("ORD-001")
end
```

### Pattern 3: Token Expiration Handling
```ruby
def execute_with_token_retry(&block)
  attempt = 1
  max_attempts = 2
  
  begin
    block.call
  rescue Mintsoft::AuthenticationError => e
    if e.status_code == 401 && attempt < max_attempts
      puts "Token expired, refreshing..."
      # Get new token
      auth_response = @auth_client.auth.authenticate(@username, @password)
      @current_token = auth_response.token
      
      attempt += 1
      retry
    else
      raise e
    end
  end
end

# Usage
execute_with_token_retry do
  client = Mintsoft::Client.new(token: @current_token)
  orders = client.orders.search("ORD-001")
end
```

## Testing Examples

### Test Setup with Mock Responses
```ruby
require 'rspec'
require 'webmock/rspec'
require 'mintsoft'

RSpec.describe 'Mintsoft Integration' do
  before do
    WebMock.disable_net_connect!
  end
  
  let(:auth_response_body) do
    {
      'token' => 'mock_api_token_12345',
      'expires_in' => 86400,
      'token_type' => 'Bearer'
    }
  end
  
  let(:orders_response_body) do
    [
      {
        'id' => 123,
        'order_number' => 'ORD-2024-001',
        'status' => 'pending',
        'customer_id' => 456
      }
    ]
  end
  
  describe 'authentication and order search' do
    it 'authenticates and searches for orders' do
      # Mock authentication endpoint
      stub_request(:post, 'https://api.mintsoft.com/api/auth')
        .with(body: { username: 'testuser', password: 'testpass' }.to_json)
        .to_return(
          status: 200,
          body: auth_response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      
      # Mock order search endpoint
      stub_request(:get, 'https://api.mintsoft.com/api/Order/Search')
        .with(query: { OrderNumber: 'ORD-2024-001' })
        .to_return(
          status: 200,
          body: orders_response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      
      # Test authentication
      auth_client = Mintsoft::AuthClient.new
      auth_response = auth_client.auth.authenticate('testuser', 'testpass')
      
      expect(auth_response.token).to eq('mock_api_token_12345')
      expect(auth_response.valid?).to be true
      
      # Test order search
      client = Mintsoft::Client.new(token: auth_response.token)
      orders = client.orders.search('ORD-2024-001')
      
      expect(orders.length).to eq(1)
      expect(orders.first.order_number).to eq('ORD-2024-001')
    end
  end
end
```

This comprehensive set of examples demonstrates various usage patterns for the Mintsoft gem, from basic operations to advanced token management and error handling strategies.