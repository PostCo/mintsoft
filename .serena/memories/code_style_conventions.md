# Code Style Conventions

## Ruby Style Guide
- **Linter**: StandardRB (standard gem ~> 1.3)
- **Ruby Version**: >= 3.0.0 (configured in .standard.yml)
- **String Literals**: frozen_string_literal: true (enforced in all files)

## Naming Conventions
- **Module/Class**: PascalCase (e.g., `Mintsoft`, `Mintsoft::Error`)
- **Methods/Variables**: snake_case 
- **Constants**: SCREAMING_SNAKE_CASE
- **Files**: snake_case matching class/module names

## File Organization
- One class/module per file
- File paths match module structure (lib/mintsoft/version.rb → Mintsoft::VERSION)
- All source files in lib/ directory
- Test files mirror lib/ structure in spec/

## Code Patterns
- Use `require_relative` for internal dependencies
- Inherit custom errors from StandardError
- Follow standard gem patterns for version management
- Use proper module namespacing

## Documentation Style
- Use YARD-style documentation comments
- Include examples in method documentation
- Keep README.md updated with usage instructions

## Testing Conventions  
- RSpec with expect syntax (no should syntax)
- Disable monkey patching (`config.disable_monkey_patching!`)
- Use descriptive test names
- Store test status in `.rspec_status` file