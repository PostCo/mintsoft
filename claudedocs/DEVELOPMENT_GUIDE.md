# Mintsoft Development Guide

## Quick Start

### Initial Setup
```bash
# Clone and setup
git clone https://github.com/Postco/mintsoft.git
cd mintsoft
bin/setup                    # Install dependencies
```

### Development Workflow
```bash
# Interactive development
bin/console                  # Start console with gem loaded

# Testing
bundle exec rake spec        # Run test suite
bundle exec rspec           # Alternative test command

# Code quality
bundle exec rake standard    # Run linter
bundle exec standardrb --fix # Auto-fix style issues

# Complete validation
bundle exec rake            # Run tests + linting
```

## Code Standards

### Style Guide
- **Linter**: StandardRB with Ruby 3.0+ target
- **String Literals**: `frozen_string_literal: true` required
- **Naming**: snake_case files, PascalCase classes
- **Testing**: RSpec with expect syntax, no monkey patching

### File Organization
```ruby
# lib/mintsoft/feature.rb
# frozen_string_literal: true

module Mintsoft
  class Feature
    # Implementation
  end
end
```

### Testing Pattern
```ruby
# spec/mintsoft/feature_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mintsoft::Feature do
  describe "#method" do
    it "does something specific" do
      expect(subject.method).to eq(expected_result)
    end
  end
end
```

## Development Environment

### System Requirements
- **Ruby**: >= 3.0.0
- **Bundler**: Latest version
- **Git**: For version control
- **macOS**: Darwin 24.6.0 (current environment)

### Editor Configuration
- **Ruby LSP**: Enabled (cache in `.ruby-lsp/`)
- **Serena**: Project configuration in `.serena/`
- **Cursor**: IDE integration available

## Quality Gates

### Pre-Commit Checklist
- [ ] Tests pass: `bundle exec rake spec`
- [ ] Style valid: `bundle exec rake standard`  
- [ ] No syntax errors
- [ ] Frozen string literals added
- [ ] Documentation updated if needed

### Release Process
1. Update `lib/mintsoft/version.rb`
2. Update `CHANGELOG.md`
3. Run `bundle exec rake` (full validation)
4. Commit changes
5. Run `bundle exec rake release`

## Architecture Patterns

### Error Handling
```ruby
module Mintsoft
  class Error < StandardError; end
  class APIError < Error; end
  class AuthenticationError < APIError; end
end
```

### Module Structure
```ruby
# Planned structure for API wrapper
module Mintsoft
  class Client
    # Main API client
  end
  
  module Resources
    class Orders
      # Order management
    end
    
    class Products  
      # Product management
    end
  end
end
```

### Configuration Pattern
```ruby
module Mintsoft
  class << self
    attr_accessor :api_key, :api_url
    
    def configure
      yield self
    end
  end
end

# Usage
Mintsoft.configure do |config|
  config.api_key = "your_key"
  config.api_url = "https://api.mintsoft.com"
end
```

## Testing Strategy

### Test Organization
```
spec/
├── spec_helper.rb          # RSpec configuration
├── mintsoft_spec.rb        # Main module tests
└── mintsoft/              # Feature-specific tests
    ├── client_spec.rb
    └── resources/
        ├── orders_spec.rb
        └── products_spec.rb
```

### Test Patterns
- **Unit tests**: Test individual classes/methods
- **Integration tests**: Test API interactions (with VCR)
- **Mock external APIs**: Use webmock for HTTP requests
- **Descriptive names**: Clear test descriptions

## Common Commands

### Development
```bash
bin/console                  # Interactive console
bundle exec rake            # Full test + lint
bundle exec rake spec       # Tests only
bundle exec rake standard   # Linting only
```

### Debugging
```bash
bundle exec rspec --format documentation
bundle exec standardrb --format json
bundle install --verbose
```

### Local Installation
```bash
bundle exec rake install    # Install locally
gem uninstall mintsoft      # Remove local install
```