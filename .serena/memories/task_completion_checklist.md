# Task Completion Checklist

## Before Committing Code
- [ ] **Tests Pass**: Run `bundle exec rake spec` - all tests must pass
- [ ] **Code Style**: Run `bundle exec rake standard` - no linting errors
- [ ] **Full Validation**: Run `bundle exec rake` (runs both spec + standard)

## Code Quality Gates
- [ ] **No Syntax Errors**: Ruby files parse correctly
- [ ] **Proper Requires**: All dependencies properly required
- [ ] **Frozen String Literals**: All new files include `# frozen_string_literal: true`
- [ ] **Naming Conventions**: Follow snake_case for files, PascalCase for classes

## Documentation Updates
- [ ] **README.md**: Update if public API changes
- [ ] **CHANGELOG.md**: Add entries for notable changes
- [ ] **Version**: Update `lib/mintsoft/version.rb` if releasing
- [ ] **Comments**: Add YARD documentation for new public methods

## Testing Requirements
- [ ] **Test Coverage**: New code has corresponding specs
- [ ] **Test Naming**: Descriptive spec names using expect syntax
- [ ] **No Monkey Patching**: Tests use modern RSpec configuration

## Release Preparation (when applicable)
- [ ] **Version Bump**: Update VERSION constant
- [ ] **Changelog**: Document changes
- [ ] **Gemspec**: Verify metadata is current
- [ ] **Git Clean**: Working directory clean before release

## Emergency Fixes
If urgent fix needed:
1. Run `bundle exec rspec` (faster than full rake)
2. Fix failing tests
3. Run `bundle exec standardrb --fix` (auto-fix style)
4. Commit and push

## Standard Development Loop
```bash
# Quick validation
bundle exec rake           # Full test + lint suite

# Fast iteration  
bundle exec rspec          # Tests only
bundle exec standardrb     # Linting only
```