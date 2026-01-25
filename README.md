# kitchen-omnibus-chef

!!! DEPRECATED !!! Please use kitchen-chef-enterprise or kitchen-cinc gems instead.

A Test Kitchen provisioner for Chef Infra Client that downloads and installs omnibus packages.

## Overview

This Test Kitchen plugin provides a provisioner that automatically downloads and installs the desired version of Chef Infra Client on your test instances using Chef's omnitruck API. This allows you to test your cookbooks against different Chef versions without pre-installing Chef on your images.

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
    attributes:
```

### Configuration Options

The provisioner supports the following configuration options:

#### `product_name`

- **Type:** String
- **Default:** `chef`
- **Description:** The product to install. Typically `chef` for Chef Infra Client.

#### `channel`

- **Type:** String
- **Default:** `stable`
- **Options:** `stable`, `current`
- **Description:** The release channel to install from.

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

#### `download_url_override`

- **Type:** String
- **Default:** none
- **Description:** Override the download URL for custom package locations.

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
  download_url_override: https://my-mirror.local/chef-packages/chef_18.3.0-1_amd64.deb
```

#### Installing from Current Channel

To test with the latest unstable builds:

```yaml
provisioner:
  name: chef_infra
  channel: current
  version: latest
```

#### Always Reinstall Chef

Useful for testing installation scripts or ensuring a clean state:

```yaml
provisioner:
  name: chef_infra
  install_strategy: always
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
