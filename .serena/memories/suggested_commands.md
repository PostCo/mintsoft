# Suggested Commands

## Development Setup
```bash
# Initial setup (run once)
bin/setup                    # Install dependencies and setup environment
bundle install              # Install/update gem dependencies

# Interactive development
bin/console                  # Start IRB console with gem loaded
```

## Testing
```bash
# Run all tests
bundle exec rake spec        # Run RSpec test suite
bundle exec rspec           # Alternative way to run tests
bundle exec rspec spec/path/to/specific_spec.rb  # Run specific test file

# Test with coverage
bundle exec rspec --format documentation  # Detailed test output
```

## Code Quality
```bash
# Linting and formatting
bundle exec rake standard    # Run StandardRB linter
bundle exec standardrb       # Alternative StandardRB command
bundle exec standardrb --fix # Auto-fix style issues

# Run default task (tests + linting)
bundle exec rake            # Runs both spec and standard tasks
rake                        # Shorthand if rake is in PATH
```

## Build and Release
```bash
# Local development
bundle exec rake install    # Install gem locally for testing
gem uninstall mintsoft      # Remove local installation

# Release process (when ready)
# 1. Update version in lib/mintsoft/version.rb
# 2. Update CHANGELOG.md
bundle exec rake release    # Create git tag and push to RubyGems
```

## Git Workflow
```bash
git status                  # Check current state
git add .                   # Stage changes
git commit -m "message"     # Commit with descriptive message
git push origin main        # Push to remote
```

## macOS-Specific Commands
```bash
# File operations
ls -la                      # List files with details
find . -name "*.rb"         # Find Ruby files
grep -r "pattern" lib/      # Search for patterns in code
open .                      # Open current directory in Finder
```