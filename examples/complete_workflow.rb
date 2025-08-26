#!/usr/bin/env ruby
# frozen_string_literal: true

# Complete workflow example for the Mintsoft gem
# This demonstrates all 5 endpoints working together

require "mintsoft"

# Step 1: Authentication using AuthClient
puts "=== Step 1: Authentication ==="
auth_client = Mintsoft::AuthClient.new
begin
  auth_response = auth_client.auth.authenticate(
    ENV.fetch("MINTSOFT_USERNAME"),
    ENV.fetch("MINTSOFT_PASSWORD")
  )
  
  puts "✅ Authentication successful!"
  puts "Token: #{auth_response.token[0...10]}..."
  puts "Expires at: #{auth_response.expires_at}"
  puts "Expired?: #{auth_response.expired?}"
rescue Mintsoft::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  exit 1
rescue KeyError => e
  puts "❌ Environment variable not set: #{e.message}"
  puts "Please set MINTSOFT_USERNAME and MINTSOFT_PASSWORD environment variables"
  exit 1
end

# Step 2: Initialize client with token
puts "\n=== Step 2: Initialize Client ==="
client = Mintsoft::Client.new(token: auth_response.token)
puts "✅ Client initialized with token"

# Step 3: Search for orders
puts "\n=== Step 3: Search Orders ==="
order_number = "ORD-2024-001" # Change this to a real order number in your system
begin
  orders = client.orders.search(order_number)
  
  if orders.empty?
    puts "⚠️  No orders found with number: #{order_number}"
    puts "Please try with a different order number"
    exit 1
  end
  
  order = orders.first
  puts "✅ Found #{orders.size} order(s)"
  puts "Order ID: #{order.id}"
  puts "Order Number: #{order.order_number}"
  puts "Customer ID: #{order.customer_id}" if order.respond_to?(:customer_id)
  puts "Status: #{order.status}" if order.respond_to?(:status)
  
rescue Mintsoft::ValidationError => e
  puts "❌ Validation error: #{e.message}"
  exit 1
rescue Mintsoft::AuthenticationError => e
  puts "❌ Authentication error: #{e.message}"
  puts "Token may have expired. Please re-authenticate."
  exit 1
rescue Mintsoft::APIError => e
  puts "❌ API error: #{e.message}"
  exit 1
end

# Step 4: Get return reasons
puts "\n=== Step 4: Get Return Reasons ==="
begin
  reasons = client.returns.reasons
  puts "✅ Found #{reasons.size} return reason(s)"
  
  reasons.each do |reason|
    status = reason.active? ? "✅" : "❌"
    puts "  #{status} #{reason.name} (ID: #{reason.id}): #{reason.description}"
  end
  
  # Select the first active reason for demo
  selected_reason = reasons.find(&:active?)
  if selected_reason.nil?
    puts "❌ No active return reasons found"
    exit 1
  end
  
  puts "\n🎯 Selected reason: #{selected_reason.name}"
  
rescue Mintsoft::APIError => e
  puts "❌ API error: #{e.message}"
  exit 1
end

# Step 5: Create return
puts "\n=== Step 5: Create Return ==="
begin
  return_obj = client.returns.create(order.id)
  puts "✅ Return created successfully!"
  puts "Return ID: #{return_obj.id}"
  puts "Order ID: #{return_obj.order_id}"
  puts "Status: #{return_obj.status}"
  
rescue Mintsoft::ValidationError => e
  puts "❌ Validation error: #{e.message}"
  exit 1
rescue Mintsoft::APIError => e
  puts "❌ API error: #{e.message}"
  exit 1
end

# Step 6: Add item to return
puts "\n=== Step 6: Add Item to Return ==="
item_attributes = {
  product_id: 123,                    # Replace with actual product ID
  quantity: 2,                        # Quantity to return
  reason_id: selected_reason.id,      # Selected return reason
  unit_value: 25.00,                  # Unit value
  notes: "Damaged during shipping"    # Optional notes
}

begin
  success = client.returns.add_item(return_obj.id, item_attributes)
  
  if success
    puts "✅ Item added to return successfully!"
    puts "Product ID: #{item_attributes[:product_id]}"
    puts "Quantity: #{item_attributes[:quantity]}"
    puts "Reason: #{selected_reason.name}"
    puts "Unit Value: $#{item_attributes[:unit_value]}"
    puts "Notes: #{item_attributes[:notes]}"
  else
    puts "❌ Failed to add item to return"
  end
  
rescue Mintsoft::ValidationError => e
  puts "❌ Validation error: #{e.message}"
rescue Mintsoft::APIError => e
  puts "❌ API error: #{e.message}"
end

puts "\n=== Workflow Complete ==="
puts "🎉 Successfully completed the full Mintsoft API workflow!"
puts "   1. ✅ Authenticated and got token"
puts "   2. ✅ Initialized client"
puts "   3. ✅ Searched for orders"
puts "   4. ✅ Retrieved return reasons"
puts "   5. ✅ Created return"
puts "   6. ✅ Added item to return"