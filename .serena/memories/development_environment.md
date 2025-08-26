# Development Environment

## System Requirements
- **OS**: macOS (Darwin 24.6.0)
- **Ruby**: >= 3.0.0 (as specified in gemspec and .standard.yml)
- **Bundler**: For dependency management
- **Git**: Version control

## IDE/Editor Setup
- **Ruby LSP**: Cache directory at `.ruby-lsp/` 
- **Cursor**: Connected IDE with project integration
- **Serena**: Project configuration in `.serena/project.yml`

## Key Configuration Files
- `.rspec` - RSpec output format and options
- `.standard.yml` - StandardRB configuration (Ruby 3.0 target)
- `Gemfile` - Development dependencies
- `Rakefile` - Task definitions (default: spec + standard)

## Development Workflow
1. **Setup**: Run `bin/setup` to install dependencies
2. **Code**: Edit files in `lib/` directory
3. **Test**: Run `bundle exec rake spec` 
4. **Lint**: Run `bundle exec rake standard`
5. **Console**: Use `bin/console` for interactive testing
6. **Commit**: Run full `bundle exec rake` before committing

## Dependencies
- **rspec** (~> 3.0) - Testing framework
- **standard** (~> 1.3) - Code formatting and linting  
- **rake** (~> 13.0) - Build automation

## Project Patterns
- Follows standard Ruby gem conventions
- Uses frozen string literals
- RSpec with modern configuration (no monkey patching)
- StandardRB for consistent code style