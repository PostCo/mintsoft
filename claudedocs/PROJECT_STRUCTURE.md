# Mintsoft Project Structure Documentation

## Overview
Mintsoft is a Ruby gem providing an API wrapper for the Mintsoft platform. Currently in early development (v0.1.0), the project follows standard Ruby gem conventions and is ready for API implementation.

## Directory Structure

```
mintsoft/
├── 📁 lib/                    # Main source code
│   ├── mintsoft.rb           # 🔸 Main entry point and Error class
│   └── mintsoft/
│       └── version.rb        # 🔸 Version constant definition
├── 📁 spec/                   # Test suite
│   ├── spec_helper.rb        # 🔸 RSpec configuration
│   └── mintsoft_spec.rb      # 🔸 Main test file
├── 📁 bin/                    # Executable scripts
│   ├── console              # 🔸 Interactive Ruby console
│   └── setup                # 🔸 Development setup script
├── 📁 sig/                    # Type signatures (RBS/Sorbet)
├── 📁 .github/               # GitHub workflows and templates
├── 📁 .ruby-lsp/             # Ruby LSP cache
├── 📁 .serena/               # Serena project configuration
└── 📄 Configuration Files
    ├── mintsoft.gemspec      # 🔸 Gem specification
    ├── Gemfile              # 🔸 Development dependencies  
    ├── Rakefile             # 🔸 Build tasks
    ├── .rspec               # 🔸 RSpec settings
    ├── .standard.yml        # 🔸 StandardRB config
    └── README.md            # 🔸 Project documentation
```

## Key Components

### Core Files
- **lib/mintsoft.rb**: Main module with base Error class
- **lib/mintsoft/version.rb**: VERSION constant (currently 0.1.0)
- **mintsoft.gemspec**: Gem metadata and dependencies

### Development Tools
- **bin/console**: IRB session with gem loaded
- **bin/setup**: Automated dependency installation
- **Rakefile**: Default task runs spec + standard

### Testing Infrastructure
- **spec/**: RSpec test suite with modern configuration
- **No monkey patching enabled**
- **Documentation format output**

## Dependencies

### Runtime
- Ruby >= 3.0.0
- No external runtime dependencies currently

### Development
- **rspec** (~> 3.0): Testing framework
- **standard** (~> 1.3): Code linting and formatting
- **rake** (~> 13.0): Build automation

## Development Status
✅ Basic gem structure complete  
✅ Testing framework configured  
✅ Code style tools setup  
🔄 API wrapper implementation needed  
🔄 Documentation needs updating  
🔄 Usage examples required  

## Next Steps
1. Implement Mintsoft API client classes
2. Add comprehensive test coverage
3. Update README with usage instructions  
4. Add API documentation
5. Configure CI/CD pipeline