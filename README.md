# kitchen-omnibus-chef

[![Gem Version](https://badge.fury.io/rb/kitchen-omnibus-chef.svg)](https://badge.fury.io/rb/kitchen-omnibus-chef)

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

#### `product_version`

- **Type:** String/Symbol
- **Default:** `:latest`
- **Description:** Version of the product to install when using `product_name`. The modern equivalent of `version`.

#### Legacy omnibus options

These predate `product_name` and are used when it is not set.

| Option | Default | Description |
| --- | --- | --- |
| `require_chef_omnibus` | `true` | Install Chef Infra Client via omnibus. `true` for the latest, a version string to pin, or `false` to skip installation entirely. |
| `chef_omnibus_url` | `https://omnitruck.chef.io/install.sh` | URL of the omnibus install script. |
| `chef_omnibus_install_options` | `nil` | Extra options appended to the omnibus install command. |
| `chef_omnibus_root` | `/opt/chef` | Root directory of the omnibus installation on the instance. |

### Run list and attributes

| Option | Default | Description |
| --- | --- | --- |
| `run_list` | `[]` | Run list applied to the instance. Usually set per suite. |
| `attributes` | `{}` | Node attributes merged into the run. |
| `json_attributes` | `true` | Write attributes to a JSON file and pass it to the client. |
| `named_run_list` | *unset* | Named run list to use from a Policyfile. |
| `policy_group` | `nil` | Policy group to use from a Policyfile. |

### Cookbook resolution

| Option | Default | Description |
| --- | --- | --- |
| `policyfile_path` | *auto* | Path to a `Policyfile.rb`. Enables Policyfile resolution. |
| `policyfile` | `nil` | Legacy alias for `policyfile_path`. |
| `berksfile_path` | *auto* | Path to a `Berksfile`. Enables Berkshelf resolution. |
| `berksfile` | *auto* | Alternate spelling of `berksfile_path`; `berksfile_path` wins when both are set. |
| `always_update_cookbooks` | `true` | Update cookbooks on every converge rather than reusing the resolved set. |
| `cookbook_files_glob` | *see source* | Glob controlling which cookbook files are copied into the sandbox. |

### Converge behaviour

| Option | Default | Description |
| --- | --- | --- |
| `log_level` | Test Kitchen's log level | Log level passed to the client. |
| `log_file` | `nil` | Write client output to this file on the instance. |
| `profile_ruby` | `false` | Enable Ruby profiling during the run. |
| `deprecations_as_errors` | `false` | Treat Chef deprecation warnings as errors. |
| `multiple_converge` | `1` | Number of times to converge in a single `converge` action. |
| `enforce_idempotency` | `false` | Fail if the final converge still makes changes. Use with `multiple_converge: 2`. |
| `retry_on_exit_code` | `[35, 213]` | Exit codes that cause the converge to be retried. 35 is "reboot required", 213 is "client upgraded". |
| `slow_resource_report` | *unset* | Emit the slow resource report at the end of the run. |
| `client_rb` | `{}` | Extra settings written into `client.rb` (`chef_infra` / `chef_zero` / `chef_target`). |
| `solo_rb` | `{}` | Extra settings written into `solo.rb` (`chef_solo`). |
| `legacy_mode` | `false` | Pass `--legacy-mode` to `chef-solo` (`chef_solo` only). |
| `chef_zero_host` | `nil` | Host the in-memory Chef Zero server binds to. |
| `chef_zero_port` | `8889` | Port the in-memory Chef Zero server binds to. |
| `sudo` | `true` | Run the client under sudo. Under `chef_target` this defaults to `true` and is applied locally. |

### Paths

Sandbox paths are on your workstation; the rest are on the instance.

| Option | Default | Description |
| --- | --- | --- |
| `root_path` | driver default | Directory on the instance the sandbox is copied into. Every other on-instance path is joined against it. |
| `config_path` | `nil` | Path to an existing config file to use instead of a generated one. |
| `data_path` | *auto* | Local `data` directory copied to the instance. |
| `data_bags_path` | *auto* | Local `data_bags` directory. |
| `environments_path` | *auto* | Local `environments` directory. |
| `nodes_path` | *auto* | Local `nodes` directory. |
| `roles_path` | *auto* | Local `roles` directory. |
| `clients_path` | *auto* | Local `clients` directory. |
| `encrypted_data_bag_secret_key_path` | *auto* | Local path to the encrypted data bag secret. |
| `chef_client_path` | *auto* | Path to `chef-client` on the instance (`chef_infra` / `chef_zero` / `chef_target`). |
| `chef_solo_path` | *auto* | Path to `chef-solo` on the instance (`chef_solo`). |
| `chef_apply_path` | *auto* | Path to `chef-apply` on the instance (`chef_apply`). |
| `apply_path` | *auto* | Path to the recipe applied by `chef_apply`. |
| `ruby_bindir` | *auto* | Directory containing the Ruby that runs the client. |

### Target mode file transfer

`chef_target` runs the converge from your workstation, so it can move files around the run.

| Option | Default | Description |
| --- | --- | --- |
| `uploads` | `{}` | Files copied to the instance before the converge. Keys are local paths, values remote destinations. |
| `downloads` | `{}` | Files copied back after the converge. Keys are remote paths, values local destinations. |

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

## Running Test Kitchen

Once configured, use the standard Test Kitchen commands:

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

## Using with Cinc

This gem is the Chef Infra Client provisioner, and the commands above assume
[Chef Workstation](https://www.chef.io/downloads/tools/workstation).

If you are using [Cinc Workstation](https://cinc.sh/start/workstation/), or you
are a community user affected by the licensed-download changes described in the
[deprecation notice](#%EF%B8%8F-important-deprecation-notice), use
[kitchen-cinc](https://gitlab.com/cinc-project/kitchen-cinc) instead. It provides
the same provisioners under `cinc_*` names, installing Cinc Client from the Cinc
omnitruck API rather than Chef's:

```yaml
provisioner:
  name: cinc_infra
```

kitchen-cinc also registers the `chef_*` names, so an existing `kitchen.yml`
using `chef_infra` keeps working and transparently runs the Cinc equivalent. See
[Enterprise Gem Integration](#enterprise-gem-integration) below for how the
`chef_*` names are resolved when several of these gems are installed.

## Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/test-kitchen/kitchen-omnibus-chef). See
[CONTRIBUTING.md](CONTRIBUTING.md) for development setup, how to run the tests,
and the release process.

## License

Apache 2.0 (see [LICENSE])

[license]: https://github.com/test-kitchen/kitchen-omnibus-chef/blob/main/LICENSE
