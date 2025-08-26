# Mintsoft Ruby Gem

A Ruby gem providing a comprehensive API wrapper for the Mintsoft platform, enabling seamless integration with inventory management, order processing, and e-commerce operations.

[![Gem Version](https://badge.fury.io/rb/mintsoft.svg)](https://badge.fury.io/rb/mintsoft)
[![Ruby](https://github.com/Postco/mintsoft/workflows/Ruby/badge.svg)](https://github.com/Postco/mintsoft/actions)

## Features

- 🚀 **Simple API**: Intuitive Ruby interface for Mintsoft operations
- 🛡️ **Error Handling**: Comprehensive error classes with detailed messages  
- 📦 **Resource Management**: Orders, Products, Inventory, and Customer management
- 🔄 **Retry Logic**: Automatic retry with exponential backoff
- 📊 **Logging**: Built-in request/response logging
- ✅ **Well Tested**: Comprehensive test suite with VCR cassettes
- 📚 **Documentation**: Extensive API documentation and examples

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mintsoft'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install mintsoft
```

## Quick Start

### Configuration
```ruby
require 'mintsoft'

Mintsoft.configure do |config|
  config.api_key = ENV['MINTSOFT_API_KEY']
  config.api_url = 'https://api.mintsoft.com/v1'
end
```

### Basic Usage
```ruby
# Initialize client
client = Mintsoft::Client.new

# Manage orders
orders = client.orders.list
order = client.orders.get(order_id)

# Manage products  
products = client.products.list(category: 'electronics')
product = client.products.create({
  name: 'New Product',
  sku: 'PROD-001',
  price: 29.99
})

# Handle inventory
inventory = client.inventory.list
client.inventory.update(product_id, quantity: 100)
```

## API Resources

### Orders
- `orders.list(options = {})` - List orders with optional filters
- `orders.get(id)` - Get specific order details
- `orders.create(attributes)` - Create new order
- `orders.update(id, attributes)` - Update existing order
- `orders.cancel(id)` - Cancel order

### Products
- `products.list(options = {})` - List products with optional filters
- `products.get(id)` - Get specific product details
- `products.create(attributes)` - Create new product
- `products.update(id, attributes)` - Update existing product
- `products.delete(id)` - Delete product

### Inventory
- `inventory.list()` - Get all inventory levels
- `inventory.get(product_id)` - Get inventory for specific product
- `inventory.update(product_id, attributes)` - Update inventory levels
- `inventory.movements(product_id)` - Get inventory movement history

### Customers
- `customers.list(options = {})` - List customers with optional filters
- `customers.get(id)` - Get specific customer details
- `customers.create(attributes)` - Create new customer
- `customers.update(id, attributes)` - Update existing customer

## Error Handling

```ruby
begin
  order = client.orders.get(order_id)
rescue Mintsoft::AuthenticationError => e
  puts "Invalid API key: #{e.message}"
rescue Mintsoft::NotFoundError => e
  puts "Order not found: #{e.message}"
rescue Mintsoft::APIError => e
  puts "API error (#{e.status_code}): #{e.message}"
rescue Mintsoft::Error => e
  puts "General error: #{e.message}"
end
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `api_key` | `nil` | Your Mintsoft API key (required) |
| `api_url` | `https://api.mintsoft.com/v1` | Base API URL |
| `timeout` | `30` | Request timeout (seconds) |
| `retry_attempts` | `3` | Number of retry attempts |
| `retry_delay` | `1` | Delay between retries (seconds) |
| `logger` | `nil` | Custom logger instance |
| `log_level` | `:info` | Logging level |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Development Commands
```bash
# Setup
bin/setup                    # Install dependencies

# Testing
bundle exec rake spec        # Run test suite  
bundle exec rspec           # Alternative test runner

# Code Quality
bundle exec rake standard    # Run linter
bundle exec standardrb --fix # Auto-fix style issues
bundle exec rake            # Run tests + linting

# Console
bin/console                 # Interactive console with gem loaded
```

### Code Style
This project uses [StandardRB](https://github.com/standardrb/standard) for code formatting and style enforcement. Run `bundle exec standardrb --fix` to automatically fix style issues.

## Testing
The test suite uses RSpec with VCR for recording HTTP interactions. To run tests:

```bash
bundle exec rake spec
```

For development against real API (use carefully):
```bash
MINTSOFT_API_KEY=your_key bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Postco/mintsoft. This project is intended to be a safe, welcoming space for collaboration.

### Contribution Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure tests pass (`bundle exec rake`)
6. Commit changes (`git commit -am 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Create Pull Request

## Documentation

- [API Documentation](claudedocs/API_DOCUMENTATION.md) - Detailed API reference
- [Development Guide](claudedocs/DEVELOPMENT_GUIDE.md) - Setup and development workflow
- [Project Structure](claudedocs/PROJECT_STRUCTURE.md) - Codebase organization

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mintsoft project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Postco/mintsoft/blob/main/CODE_OF_CONDUCT.md).

## Support

- 📧 **Email**: andygg1996personal@gmail.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/Postco/mintsoft/issues)
- 📖 **Documentation**: [GitHub Wiki](https://github.com/Postco/mintsoft/wiki)

---

**Status**: Early development (v0.1.0) - API structure planning phase

Built with ❤️ by [Andy Chong](https://github.com/andychong)