# Copilot Instructions for kitchen-omnibus-chef

## Project Overview

kitchen-omnibus-chef is a Test Kitchen plugin that provides Chef provisioners for testing cookbooks and infrastructure code. This gem is included in Chef Workstation but can also be installed standalone.

### Key Features
- Automatic downloading and installation of Chef Infra Client using Chef's omnitruck API
- Support for multiple provisioner types: ChefInfra, ChefZero (deprecated), ChefSolo, ChefApply, and ChefTarget
- Integration with Policyfiles and Berkshelf for cookbook dependency resolution
- Supports licensed Chef product downloads with license key configuration
- Built on Mixlib::Install for Chef package installation

## Architecture

### Provisioner Hierarchy
- `ChefBase` - Base class with common functionality for all Chef provisioners
- `ChefInfra` - Main provisioner using chef-client in local mode (preferred)
- `ChefZero` - Deprecated alias for ChefInfra (maintains compatibility)
- `ChefSolo` - Traditional chef-solo provisioner (not thread-safe due to Berkshelf)
- `ChefApply` - Runs recipes using chef-apply
- `ChefTarget` - Target mode provisioner for remote execution (requires Chef 19.0.0+)

### Key Module Structure
- `/lib/kitchen/provisioner/` - Main provisioner implementations
- `/lib/kitchen/provisioner/chef/` - Support modules (Policyfile, Berkshelf, CommonSandbox)
- `/spec/` - Unit tests using Minitest

## Configuration Guidelines

### Critical Configuration Names

#### `chef_license_key` (NOT `license_key`)
- **Purpose**: Specify a Chef license key for licensed Chef product downloads
- **Environment Variable**: `CHEF_LICENSE_KEY`
- **Internal Mapping**: Maps to `:license_id` in Mixlib::Install options
- **Example**:
  ```yaml
  provisioner:
    name: chef_infra
    chef_license_key: free-79df705d-b685-419a-8b68-88401f74ff72-3999
  ```

#### Product Installation Options (RFC 091)
These are the modern configuration options (preferred over deprecated options):

- `product_name` - Product to install (`chef` or `chef-workstation`)
- `product_version` - Version to install (default: `:latest`)
- `channel` - Release channel (`:stable` or `:current`)
- `install_strategy` - When to install (`"once"` or `"always"`)
- `download_url` - Override download URL for air-gapped environments
- `checksum` - SHA256 checksum for download verification
- `platform` - Override platform detection
- `platform_version` - Override platform version detection
- `architecture` - Override architecture detection

#### Deprecated Options (Still Supported)
- `require_chef_omnibus` - Use `product_name` + `install_strategy` instead
- `chef_omnibus_url` - Use `download_url` instead
- `chef_omnibus_install_options` - Use new configuration options instead

### Chef Configuration Options
- `chef_license` - Accept Chef EULA (`"accept"`, `"accept-no-persist"`, `"accept-silent"`)
- `run_list` - Chef run list (default: `[]`)
- `attributes` - Chef attributes hash (default: `{}`)
- `log_level` - Chef log level (`"auto"` or `"debug"`)
- `log_file` - Path to Chef log file
- `profile_ruby` - Enable Ruby profiling (default: `false`)
- `multiple_converge` - Number of converge iterations (default: `1`)
- `enforce_idempotency` - Enforce idempotent converges (default: `false`)
- `retry_on_exit_code` - Exit codes to retry on (default: `[35, 213]`)

### Policyfile Configuration
- `policyfile` - Legacy compatibility option (use `policyfile_path` instead)
- `policyfile_path` - Path to Policyfile.rb (auto-detects if not set)
- `policy_group` - Policy group for policyfile export
- `always_update_cookbooks` - Update cookbooks on every run (default: `true`)

### Berkshelf Configuration
- `berksfile_path` - Path to Berksfile (auto-detects if not set)
- `always_update_cookbooks` - Update cookbooks on every run (default: `true`)

### Path Configuration
All paths are auto-calculated if not specified:
- `data_path` - Path to Chef data directory
- `data_bags_path` - Path to data bags
- `environments_path` - Path to environments
- `nodes_path` - Path to node definitions
- `roles_path` - Path to roles
- `clients_path` - Path to clients
- `encrypted_data_bag_secret_key_path` - Path to encryption key

## Development Practices

### Adding New Configuration Options

1. **Define in ChefBase**: Add `default_config` in `chef_base.rb`
   ```ruby
   default_config :my_option, default_value
   ```

2. **Update Spec Tests**: Add tests in `spec/kitchen/provisioner/chef_base_spec.rb`
   ```ruby
   it ":my_option defaults to default_value" do
     _(provisioner[:my_option]).must_equal default_value
   end
   ```

3. **Document in README**: Update README.md with usage examples

4. **Test Integration**: Add integration tests in `kitchen.yml` files

### Code Style Standards

- **Ruby Version**: Requires Ruby >= 3.1
- **Style Guide**: Uses Cookstyle/ChefStyle (see `.rubocop.yml`)
- **Test Framework**: Minitest for unit tests
- **Coverage**: RuboCop excludes `spec/**/*` from linting

### Testing Practices

#### Unit Tests
- Located in `/spec/kitchen/provisioner/`
- Use Minitest (`must_equal`, `must_be_nil`, etc.)
- Mock external dependencies (Mixlib::Install, file system operations)
- Test both default values and custom configurations

#### Integration Tests
- Use multiple `kitchen.yml` files for different scenarios:
  - `kitchen.yml` - Standard tests
  - `kitchen.dokken.yml` - Docker-based tests
  - `kitchen.exec.yml` - Execute tests
  - `kitchen.proxy.yml` - Proxy configuration tests

#### Test Patterns
```ruby
# Test default values
it ":config_option defaults to expected_value" do
  _(provisioner[:config_option]).must_equal expected_value
end

# Test with custom config
it "config_option can be set" do
  config[:config_option] = custom_value
  _(provisioner[:config_option]).must_equal custom_value
end

# Test behavior
it "will set the chef_license_key if given" do
  config[:chef_license_key] = "test-license-key-12345"
  Mixlib::Install.expects(:new).with do |opts|
    _(opts[:install_command_options][:license_id]).must_equal "test-license-key-12345"
  end.returns(installer)
  cmd
end
```

## Common Patterns

### Detecting Policyfile vs Berkshelf
The provisioner auto-detects cookbook management:
1. Checks for `Policyfile.rb` (uses Policyfile if found)
2. Falls back to `Berksfile` (uses Berkshelf if found)
3. Otherwise, expects cookbooks in standard locations

### Platform Detection
- OS type detection via `platform.os_type` (`:windows` or `:unix`)
- PowerShell detection via `powershell_shell?`
- Windows-specific path handling with `.bat` extensions

### Mixlib::Install Integration
Configuration flows from kitchen-omnibus-chef to Mixlib::Install:
- `product_name` → `:product_name`
- `product_version` → `:product_version`
- `channel` → `:channel`
- `chef_license_key` → `:install_command_options[:license_id]`
- Proxy settings → `:install_command_options` (http_proxy, https_proxy, etc.)

## Deprecation Handling

When deprecating config options:
1. Use `deprecate_config_for` macro in ChefBase
2. Provide clear migration path in deprecation message
3. Continue supporting old options for backward compatibility
4. Set `deprecations_as_errors: true` in config to test strict mode

Example:
```ruby
deprecate_config_for :old_option, Util.outdent!(<<-MSG)
  The 'old_option' attribute will be replaced by 'new_option'.
  
  # New Usage #
  provisioner:
    new_option: value
MSG
```

## Release Process

1. Determine version bump (patch/minor/major) based on changes
2. Create release prep branch (e.g., `150_release_prep`)
3. Update `lib/kitchen/provisioner/omnibus_chef_version.rb`
4. Run `rake changelog` to update CHANGELOG.md
5. Create PR for review
6. Merge to main after approval
7. Run `rake release` on main branch
8. Bump version for next development cycle

## Dependencies

### Runtime Dependencies
- `test-kitchen` >= 4.0
- `mixlib-install` >= 3.14 (Chef package installation)
- `mixlib-shellout` >= 1.2, < 4.0 (Command execution)
- `license-acceptance` >= 1.0.11, < 3.0 (Chef EULA handling)

### Optional Dependencies
- `berkshelf` - For Berkshelf-based cookbook resolution
- `chef-config` - For Chef Workstation integration

## Common Pitfalls

1. **Config Naming**: Always use `chef_license_key`, not `license_key`
2. **Thread Safety**: ChefSolo is not thread-safe due to Berkshelf dependency
3. **Product Name**: Must set `product_name` to use modern config options
4. **Windows Paths**: Remember to add `.bat` extension for Windows executables
5. **Policyfile Detection**: Auto-detection requires file named exactly `Policyfile.rb`
6. **Chef Target**: Requires Chef 19.0.0+ and Train transport
