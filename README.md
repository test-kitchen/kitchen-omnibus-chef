# kitchen-omnibus-chef

A Test Kitchen provisioner for omnibus version of Chef Infra-Client using the omnitruck url downloads

## Overview

This Test Kitchen plugin provides a driver, transport, and provisioner for rapid cookbook testing and development using Chef Infra Client.

## Installation

`Note:` kitchen-inspec ships as part of Chef Workstation. Installation is not necessary for CW users.

Add this line to your application's Gemfile:

```ruby
gem 'kitchen-omnibus-chef'
```

And then execute:

```shell
bundle
```

Or install it yourself as:

```shell
gem install kitchen-omnibus-chef
```

## Usage

In your kitchen.yml include

```yaml
provisioner:
  name: chef_infra
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/test-kitchen/kitchen-omnibus-chef>.

## License

Apache 2.0 (see [LICENSE])

[license]: https://github.com/test-kitchen/kitchen-omnibus-chef/blob/main/LICENSE
