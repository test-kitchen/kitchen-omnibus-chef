#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2014, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "../../spec_helper"

require "kitchen"
require "kitchen/provisioner/chef_zero"

describe Kitchen::Provisioner::ChefZero do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform)        { stub(os_type: nil) }
  let(:suite)           { stub(name: "fries") }

  let(:config) do
    { test_base_path: "/b", kitchen_root: "/r" }
  end

  let(:instance) do
    stub(
      name: "coolbeans",
      logger: logger,
      suite: suite,
      platform: platform
    )
  end

  let(:provisioner) do
    Kitchen::Provisioner::ChefZero.new(config).finalize_config!(instance)
  end

  it "is a subclass of ChefInfra" do
    _(Kitchen::Provisioner::ChefZero.superclass).must_equal Kitchen::Provisioner::ChefInfra
  end

  describe "enterprise gem delegation" do
    before do
      Kitchen::Provisioner::ChefBase.instance_variable_set(:@enterprise_gem_checked, false)
      Kitchen::Provisioner::ChefBase.instance_variable_set(:@enterprise_gem, nil)
    end

    it "uses standard implementation when no enterprise gem is available" do
      Gem::Specification.singleton_class.any_instance.stubs(:find_by_name).with("kitchen-chef-enterprise").raises(Gem::LoadError)
      Gem::Specification.singleton_class.any_instance.stubs(:find_by_name).with("kitchen-cinc").raises(Gem::LoadError)

      provisioner = Kitchen::Provisioner::ChefZero.new(config).finalize_config!(instance)
      # ChefZero is just an alias, so it should be a ChefZero instance
      _(provisioner.class).must_equal Kitchen::Provisioner::ChefZero
    end

    it "falls back to standard implementation when enterprise gem fails to load" do
      mock_spec = stub("gem_spec")
      Gem::Specification.singleton_class.any_instance.stubs(:find_by_name).with("kitchen-chef-enterprise").returns(mock_spec)
      Kitchen::Provisioner::ChefZero.stubs(:require).raises(LoadError.new("cannot load"))

      provisioner = Kitchen::Provisioner::ChefZero.new(config).finalize_config!(instance)
      _(provisioner.class).must_equal Kitchen::Provisioner::ChefZero
    end
  end
end
