# AuthClient Design

## Overview

The gem provides a separate `AuthClient` that handles token authentication through an `auth` resource. This keeps authentication separate from the main API client while providing a clean interface for token management.

## Architecture

```
Mintsoft Gem Structure
├── AuthClient (separate from main client)
│   └── Auth Resource (POST /api/auth)
├── Client (main API client - token only)
│   ├── Orders Resource
│   └── Returns Resource
```

## AuthClient Implementation

### 1. AuthClient Class (Faraday-based)

```ruby
# lib/mintsoft/auth_client.rb
require "faraday"
require "faraday/net_http"

module Mintsoft
  class AuthClient
    BASE_URL = "https://api.mintsoft.com".freeze

    def initialize(base_url: BASE_URL, conn_opts: {})
      @base_url = base_url
      @conn_opts = conn_opts
    end

    def connection
      @connection ||= Faraday.new do |conn|
        conn.url_prefix = @base_url
        conn.options.merge!(@conn_opts)
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end

    def auth
      @auth ||= Resources::Auth.new(self)
    end
  end
end
```

### 2. Auth Resource (Faraday-based)

```ruby
# lib/mintsoft/resources/auth.rb
module Mintsoft
  module Resources
    class Auth
      def initialize(client)
        @client = client
      end

      def authenticate(username, password)
        validate_credentials!(username, password)

        payload = {
          username: username,
          password: password
        }

        response = @client.connection.post('/api/auth', payload)

        if response.success?
          response.body # Returns token string directly
        else
          handle_auth_error(response)
        end
      end

      private

      def validate_credentials!(username, password)
        raise ValidationError, "Username is required" if username.nil? || username.empty?
        raise ValidationError, "Password is required" if password.nil? || password.empty?
      end

      def handle_auth_error(response)
        case response.status
        when 400
          raise ValidationError, "Invalid request: #{extract_error_message(response)}"
        when 401
          raise AuthenticationError, "Invalid credentials"
        when 500
          raise APIError, "Internal server error"
        else
          raise APIError, "Authentication failed: #{response.status}"
        end
      end

      def extract_error_message(response)
        return response.body['message'] if response.body.is_a?(Hash)
        'Bad request'
      end
    end
  end
end
```

### 3. BaseResource for Common Patterns

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

## Usage Examples

### 1. Basic Token Retrieval

```ruby
# Initialize auth client
auth_client = Mintsoft::AuthClient.new

# Get token directly as string
token = auth_client.auth.authenticate(
  ENV['MINTSOFT_USERNAME'],
  ENV['MINTSOFT_PASSWORD']
)

puts "Token: #{token}"

# Use token with main client
client = Mintsoft::Client.new(token: token)
orders = client.orders.search("ORD-2024-001")
```

### 2. With Error Handling

```ruby
auth_client = Mintsoft::AuthClient.new

begin
  token = auth_client.auth.authenticate(username, password)

  puts "Authentication successful!"
  puts "Token: #{token}"

  client = Mintsoft::Client.new(token: token)

rescue Mintsoft::AuthenticationError => e
  puts "Invalid credentials: #{e.message}"
rescue Mintsoft::ValidationError => e
  puts "Validation error: #{e.message}"
rescue Mintsoft::APIError => e
  puts "API error: #{e.message}"
end
```

### 3. Custom Base URL

```ruby
# For different environments
auth_client = Mintsoft::AuthClient.new(
  base_url: 'https://staging.mintsoft.com/api'
)

token = auth_client.auth.authenticate("user", "pass")

# Use with matching base URL for main client
client = Mintsoft::Client.new(
  token: token,
  base_url: 'https://staging.mintsoft.com/api'
)
```

## Updated File Structure

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
│   │   ├── orders.rb              # Orders resource
│   │   └── returns.rb             # Returns resource
│   └── objects/
│       ├── order.rb               # Order object
│       ├── return.rb              # Return object
│       └── return_reason.rb       # Return reason object
```

## Benefits

### 1. **Clean Separation**

- AuthClient for token management
- Client for API operations
- Clear responsibility boundaries

### 2. **Consistent Interface**

- Same resource pattern as main client
- Familiar API design
- Easy to understand and use

### 3. **Flexible Usage**

- Can use AuthClient independently
- Easy integration with token management systems
- Supports custom base URLs for different environments

### 4. **Enhanced Error Handling**

- Specific error types for authentication
- Detailed error messages
- Validation of input parameters

### 5. **Rich Token Information**

- Expiration tracking
- Token validation helpers
- Structured response data

## Main Entry Point Update

```ruby
# lib/mintsoft.rb
require_relative 'mintsoft/version'
require_relative 'mintsoft/errors'
require_relative 'mintsoft/base'
require_relative 'mintsoft/client'
require_relative 'mintsoft/auth_client'

# Resources
require_relative 'mintsoft/resources/base_resource'
require_relative 'mintsoft/resources/auth'
require_relative 'mintsoft/resources/orders'
require_relative 'mintsoft/resources/returns'

# Objects
require_relative 'mintsoft/objects/order'
require_relative 'mintsoft/objects/return'
require_relative 'mintsoft/objects/return_reason'

module Mintsoft
  class Error < StandardError; end
  # ... other error classes
end
```

This design provides a clean, consistent interface for authentication while maintaining the separation between token management and API operations.
