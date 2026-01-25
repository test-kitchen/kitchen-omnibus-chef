# kitchen-omnibus-chef

## ⚠️ IMPORTANT DEPRECATION NOTICE

**Omnitruck downloads are being shutdown for specific Chef Infra Client versions and will stop working entirely in the future.** This gem is also not compatible with Chef Infra Client 19+ new Habitat-based installation method.

### Recommended Migration Paths

- **For Chef customers**: Switch to [kitchen-chef-enterprise](https://github.com/chef/kitchen-chef-enterprise) (bundled in Chef Workstation 26.x+) for licensed download support
- **For community users**: Switch to [kitchen-cinc](https://gitlab.com/cinc-project/kitchen-cinc) and use Cinc provisioners like `cinc_infra`

Please refer to the [Chef blog](https://www.chef.io/blog/decoding-the-change-progress-chef-is-moving-to-licensed-downloads) for the schedule of affected versions.

---

A Test Kitchen provisioner for Chef Infra Client that downloads and installs omnibus packages.

## Overview

This Test Kitchen plugin provides provisioners that automatically download and install the desired version of Chef Infra Client on your test instances using Chef's omnitruck API or licensed download endpoints. This allows you to test your cookbooks against different Chef versions without pre-installing Chef on your images.

## Installation

**Note:** This gem ships as part of Chef Workstation. If you're using Chef Workstation, no additional installation is necessary.

For standalone installation, add this line to your Gemfile:

```ruby
gem 'kitchen-omnibus-chef'
```

Then execute:

```shell
bundle install
```

Or install it directly:

```shell
gem install kitchen-omnibus-chef
```

## Usage

### Available Provisioners

This gem provides five provisioners:

- **`chef_infra`** - Modern Chef Infra Client provisioner (recommended)
- **`chef_zero`** - Deprecated alias for chef_infra (maintained for backward compatibility)
- **`chef_solo`** - Chef Solo provisioner (note: does not support parallel converge)
- **`chef_apply`** - Chef Apply provisioner for running individual recipes
- **`chef_target`** - Chef Target Mode provisioner (requires Chef 19.0.0+, Train-based transport)

### Basic Configuration

To use the Chef Infra provisioner in your `kitchen.yml`:

```yaml
provisioner:
  name: chef_infra
```

### Complete Example

Here's a complete `kitchen.yml` example showing typical usage:

```yaml
---
driver:
  name: vagrant

provisioner:
  name: chef_infra
  product_name: chef
  install_strategy: always
  channel: stable
  chef_license: accept-no-persist

platforms:
  - name: ubuntu-24.04
  - name: almalinux-9

suites:
  - name: default
    run_list:
      - recipe[my_cookbook::default]
```

### Configuration Options

The provisioner supports the following configuration options:

#### `product_name`

- **Type:** String
- **Default:** `nil` (falls back to legacy install behavior)
- **Description:** The product to install. Set to `chef` for Chef Infra Client. Required for using licensed downloads.

#### `chef_license_key`

- **Type:** String
- **Default:** `ENV["CHEF_LICENSE_KEY"]`
- **Description:** License key for downloading licensed Chef products. Required for licensed downloads.

**Example:**

```yaml
provisioner:
  name: chef_infra
  product_name: chef
  chef_license_key: your-license-key-here
  version: latest
```

#### `channel`

- **Type:** String/Symbol
- **Default:** `stable`
- **Common Options:** `stable`, `current`
- **Description:** The release channel to install from. Accepts any symbol value.

#### `version`

- **Type:** String
- **Default:** `latest`
- **Description:** The version of Chef Infra Client to install. Can be a specific version (e.g., `18.3.0`) or `latest`.

**Example:**

```yaml
provisioner:
  name: chef_infra
  product_name: chef
  version: 18.3.0
```

#### `install_strategy`

- **Type:** String
- **Default:** `once`
- **Options:** `once`, `always`
- **Description:** When to install Chef. `once` only installs if not present, `always` reinstalls on every converge.

#### `chef_license`

- **Type:** String
- **Default:** none
- **Options:** `accept`, `accept-no-persist`, `accept-silent`
- **Description:** Accept the Chef license agreement.

#### `download_url`

- **Type:** String
- **Default:** none
- **Description:** Override the download URL for custom package locations or air-gapped environments.

#### `checksum`

- **Type:** String
- **Default:** none
- **Description:** SHA256 checksum to verify the downloaded package. Used with `download_url`.

#### `platform`, `platform_version`, `architecture`

- **Type:** String
- **Default:** Auto-detected
- **Description:** Explicitly specify platform details for package selection.

### Testing Multiple Chef Versions

You can test your cookbook against multiple Chef versions by defining multiple suites:

```yaml
provisioner:
  name: chef_infra
  chef_license: accept-no-persist

platforms:
  - name: ubuntu-22.04

suites:
  - name: chef-17
    provisioner:
      version: 17.10.0
    run_list:
      - recipe[my_cookbook::default]

  - name: chef-18
    provisioner:
      version: 18.3.0
    run_list:
      - recipe[my_cookbook::default]

  - name: chef-latest
    provisioner:
      version: latest
    run_list:
      - recipe[my_cookbook::default]
```

### Advanced Configuration

#### Custom Download URLs

For air-gapped environments or custom Chef builds:

```yaml
provisioner:
  name: chef_infra
  product_name: chef
  download_url: https://my-mirror.local/chef-packages/chef_18.3.0-1_amd64.deb
  checksum: sha256-checksum-here  # optional but recommended
```

#### Installing from Current Channel

To test with the latest unstable builds:

```yaml
provisioner:
  name: chef_infra
  product_name: chef
  channel: current
  version: latest
```

#### Always Reinstall Chef

Useful for testing installation scripts or ensuring a clean state:

```yaml
provisioner:
  name: chef_infra
  product_name: chef
  install_strategy: always
```

## Provisioner-Specific Notes

### Chef Solo

**Important:** ChefSolo does not support parallel converge due to Berkshelf not being thread-safe. Test Kitchen will run ChefSolo converges sequentially.

```yaml
provisioner:
  name: chef_solo
  product_name: chef
  chef_license: accept-no-persist
```

### Chef Apply

Chef Apply runs individual recipes without a full Chef run. Place your recipes in an `apply/` directory:

```yaml
provisioner:
  name: chef_apply
  product_name: chef

suites:
  - name: default
    run_list:
      - recipe1  # runs apply/recipe1.rb
      - recipe2  # runs apply/recipe2.rb
```

### Chef Target Mode

Chef Target Mode requires:

- Chef Infra Client **19.0.0 or later**
- A Train-based transport (e.g., `kitchen-transport-train`)

```yaml
driver:
  name: vagrant

transport:
  name: train  # Required for chef_target

provisioner:
  name: chef_target
  product_name: chef
  product_version: "19.0.0"
  chef_license: accept-no-persist
```

**Note:** Chef Target Mode has a default `install_strategy` of `"none"` since Chef runs from your local workstation.

### Chef Zero

Chef Zero is deprecated and maintained only for backward compatibility. It's an alias for ChefInfra. Use `chef_infra` instead:

```yaml
# Deprecated
provisioner:
  name: chef_zero

# Use this instead
provisioner:
  name: chef_infra
```

## Enterprise Gem Integration

kitchen-omnibus-chef automatically detects and defers to enterprise provisioner implementations when available. If you have `kitchen-chef-enterprise` or `kitchen-cinc` installed, kitchen-omnibus-chef will use their implementations instead, providing:

- Enhanced features for enterprise Chef environments
- Licensed Chef product support
- Seamless upgrade path without configuration changes

### Priority Order

When loading provisioners, kitchen-omnibus-chef checks for enterprise gems in this order:

1. **kitchen-chef-enterprise** (Progress Chef Enterprise)
2. **kitchen-cinc** (Cinc Project)
3. **kitchen-omnibus-chef** (fallback, this gem)

### Compatibility

To use enterprise features, install the enterprise gem alongside kitchen-omnibus-chef:

```shell
# For Progress Chef Enterprise
gem install kitchen-chef-enterprise

# For Cinc Project
gem install kitchen-cinc
```

Or in your Gemfile:

```ruby
# Enterprise gem (higher priority)
gem 'kitchen-chef-enterprise'

# Standard gem (fallback)
gem 'kitchen-omnibus-chef'
```

No configuration changes are needed - Test Kitchen will automatically use the enterprise implementation when available.

## Running Tests

Once configured, use standard Test Kitchen commands:

```shell
# List all test instances
kitchen list

# Create and converge a specific instance
kitchen converge default-ubuntu-2204

# Run a full test cycle
kitchen test

# Destroy all instances
kitchen destroy
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/test-kitchen/kitchen-omnibus-chef>.

## License

Apache 2.0 (see [LICENSE])

[license]: https://github.com/test-kitchen/kitchen-omnibus-chef/blob/main/LICENSE
