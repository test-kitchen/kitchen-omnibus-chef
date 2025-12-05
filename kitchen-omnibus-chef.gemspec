lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kitchen/provisioner/omnibus_chef_version"
require "English"

Gem::Specification.new do |gem|
  gem.name          = "kitchen-omnibus-chef"
  gem.version       = Kitchen::Provisioner::OMNIBUS_CHEF_VERSION
  gem.license       = "Apache-2.0"
  gem.authors       = ["Fletcher Nichol"]
  gem.email         = ["fnichol@nichol.ca"]
  gem.description   = ""
  gem.summary       = gem.description
  gem.homepage      = "https://kitchen.ci/"

  # The gemfile and gemspec are necessary for appbundler in ChefDK / Workstation
  gem.files         = %w{LICENSE kitchen-omnibus-chef.gemspec Gemfile Rakefile} + Dir.glob("{lib,support}/**/*")
  gem.executables   = %w{kitchen}
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 3.1"

  gem.add_dependency "test-kitchen",       "~> 3.9" # TODO: Bump to 4.0 once https://github.com/test-kitchen/test-kitchen/pull/2041 is merged
  gem.add_dependency "mixlib-install",     "~> 3.6"
  gem.add_dependency "mixlib-shellout",    ">= 1.2", "< 4.0"
  # Required to run the Chef provisioner local license check for remote systems
  # TK is not under Chef EULA
  gem.add_dependency "license-acceptance", ">= 1.0.11", "< 3.0" # pinning until we can confirm 3+ works
end
