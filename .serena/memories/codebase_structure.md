# Codebase Structure

## Directory Layout
```
mintsoft/
├── bin/                    # Executable scripts
│   ├── console            # Interactive Ruby console
│   └── setup              # Setup script for dependencies
├── lib/                   # Main source code
│   ├── mintsoft.rb        # Main entry point
│   └── mintsoft/          # Gem modules
│       └── version.rb     # Version definition
├── spec/                  # Test files
│   ├── spec_helper.rb     # RSpec configuration
│   └── mintsoft_spec.rb   # Main spec file
├── sig/                   # Type signatures (if using Sorbet/RBS)
├── .github/               # GitHub workflows and templates
├── .serena/               # Serena project configuration
└── .ruby-lsp/             # Ruby LSP cache
```

## Key Files
- `mintsoft.gemspec` - Gem specification and dependencies
- `Gemfile` - Development dependencies
- `Rakefile` - Build and task definitions
- `README.md` - Project documentation (needs updating)
- `.rspec` - RSpec configuration
- `.standard.yml` - StandardRB configuration
- `CHANGELOG.md` - Version history
- `LICENSE.txt` - MIT license

## Entry Points
- `lib/mintsoft.rb` - Main module requiring version and defining base Error class
- `bin/console` - Interactive development console
- `bin/setup` - Development environment setup