# Mintsoft Ruby Gem - Claude Instructions

## Project Overview

This is a Ruby gem that provides a wrapper for the Mintsoft API with token-based authentication and access to warehouse management functions.

## Core Principles

### API Response Handling - CRITICAL RULE
**DO NOT ENHANCE OR INJECT DATA TO THE RESPONSE WHEN WRAPPING THE API RESPONSE IN OBJECT**

- The `Base` class (lib/mintsoft/base.rb) wraps API responses in OpenStruct objects
- Objects should only contain data that comes directly from the API response
- DO NOT add computed properties, injected fields, or derived data
- Preserve the original response structure exactly as returned by the API
- Use `@original_response` to store the frozen, unmodified API response

### Object Design
- All API objects inherit from `Mintsoft::Objects::Base`
- Base class provides OpenStruct functionality with underscore key transformation
- Objects provide `.raw` method to access original API response
- Objects provide `.to_hash` method to convert back to hash representation
- Keep object classes simple - they are data containers, not business logic

## Project Structure

```
lib/
├── mintsoft/
│   ├── base.rb                 # Base class for all API objects
│   ├── client.rb              # Main API client
│   ├── auth_client.rb         # Authentication client
│   ├── resources/             # API resource handlers
│   └── objects/               # API response objects
│       ├── order.rb           # Order object (inherits from Base)
│       └── return.rb          # Return object (inherits from Base)
```

## Development Guidelines

### When Adding New Object Classes
1. Inherit from `Mintsoft::Objects::Base`
2. Keep the class minimal - let Base handle the data transformation
3. DO NOT add computed properties or inject additional data
4. Test with actual API responses to ensure correct transformation

### When Modifying Base Class
1. Maintain backward compatibility
2. Preserve original response data integrity
3. Ensure `to_hash` and `raw` methods continue to work
4. Test key transformation (camelCase to underscore)

### Error Handling
- All error classes should include response context and status codes
- Provide clear error messages for common scenarios
- Use appropriate HTTP status-based error classes

### Authentication
- Token management is manual - no automatic refresh
- Auth client returns token directly as string
- Client initialization requires explicit token parameter

## Testing

- Run tests with `rake spec`
- Test with real API responses when possible
- Ensure object transformation preserves data integrity
- Test error scenarios with appropriate status codes

## Key Files to Understand

1. `lib/mintsoft/base.rb` - Core object transformation logic
2. `lib/mintsoft/client.rb` - Main API client interface
3. `lib/mintsoft/auth_client.rb` - Authentication handling
4. `spec/` - Test files showing expected behavior

## When Making Changes

1. Read the existing code patterns first
2. Follow Ruby conventions and the existing style
3. **NEVER inject or enhance API response data**
4. Keep object classes simple and focused on data representation
5. Maintain the original response preservation pattern
6. Test thoroughly with real API responses

## Common Pitfalls to Avoid

- Adding computed properties to object classes
- Modifying API response data during object creation
- Breaking the `@original_response` storage pattern
- Adding business logic to data objects
- Changing key transformation behavior without testing