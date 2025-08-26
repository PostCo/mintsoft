# Mintsoft Ruby Gem

A Ruby wrapper for the Mintsoft API that provides simple token-based authentication and access to essential warehouse management functions.

## Features

- **Token-only authentication**: Manual token management for full control
- **5 Essential API endpoints**: Authentication, Order Search, Return Reasons, Create Returns, Add Return Items
- **OpenStruct-based objects**: Flexible response handling with automatic attribute conversion
- **Faraday HTTP client**: Robust HTTP handling with JSON support
- **Comprehensive error handling**: Clear error messages for common scenarios

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mintsoft'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install mintsoft

## Usage

### Basic Workflow

```ruby
require 'mintsoft'

# Step 1: Get authentication token
auth_client = Mintsoft::AuthClient.new
auth_response = auth_client.auth.authenticate("username", "password")

# Step 2: Initialize client with token
client = Mintsoft::Client.new(token: auth_response.token)

# Step 3: Search for orders
orders = client.orders.search("ORD-2024-001")
order = orders.first

# Step 4: Get return reasons
reasons = client.returns.reasons
damage_reason = reasons.find { |r| r.name.include?("Damage") }

# Step 5: Create return
return_obj = client.returns.create(order.id)

# Step 6: Add item to return
success = client.returns.add_item(return_obj.id, {
  product_id: 123,
  quantity: 2,
  reason_id: damage_reason.id,
  unit_value: 25.00,
  notes: "Damaged in shipping"
})
```

### API Reference

#### AuthClient

```ruby
# Initialize authentication client
auth_client = Mintsoft::AuthClient.new

# Authenticate and get token
auth_response = auth_client.auth.authenticate("username", "password")
puts auth_response.token
puts auth_response.expires_at
puts auth_response.expired?
```

#### Client

```ruby
# Initialize with token
client = Mintsoft::Client.new(token: "your_token_here")

# Custom base URL (optional)
client = Mintsoft::Client.new(
  token: "your_token_here",
  base_url: "https://custom.api.com"
)
```

#### Orders

```ruby
# Search for orders by order number
orders = client.orders.search("ORD-123")

# Access order properties
order = orders.first
puts order.id
puts order.order_number
puts order.customer_id
```

#### Returns

```ruby
# Get return reasons
reasons = client.returns.reasons
active_reasons = reasons.select(&:active?)

# Create return for order
return_obj = client.returns.create(order_id)

# Add item to return
client.returns.add_item(return_id, {
  product_id: 123,
  quantity: 2,
  reason_id: reason_id,
  unit_value: 25.00,
  notes: "Optional notes"
})
```

### Error Handling

```ruby
begin
  orders = client.orders.search("ORD-123")
rescue Mintsoft::AuthenticationError => e
  # Token expired or invalid
  puts "Authentication failed: #{e.message}"
rescue Mintsoft::ValidationError => e
  # Invalid request data
  puts "Validation error: #{e.message}"
rescue Mintsoft::NotFoundError => e
  # Resource not found
  puts "Not found: #{e.message}"
rescue Mintsoft::APIError => e
  # General API error
  puts "API error: #{e.message}"
end
```

### Complete Example

See [examples/complete_workflow.rb](examples/complete_workflow.rb) for a full working example.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mintsoft. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/mintsoft/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mintsoft project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mintsoft/blob/main/CODE_OF_CONDUCT.md).
