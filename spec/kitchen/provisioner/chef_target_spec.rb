#
# Author:: Thomas Heinen (<thomas.heinen@gmail.com>)
#
# Copyright (C) 2024, Thomas Heinen
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
require "kitchen/provisioner/chef_target"

module Train
  module Plugins
    module Transport
      class Dummy; end
    end
  end
end

describe Kitchen::Provisioner::ChefTarget do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform)        { stub(os_type: nil) }
  let(:suite)           { stub(name: "fries") }
  let(:transport)       { Train::Plugins::Transport::Dummy.new }
  let(:connection)      { transport.stubs(:connection).returns(nil) }

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
    Kitchen::Provisioner::ChefTarget.new(config).finalize_config!(instance)
  end

  describe "enterprise gem delegation" do
    before do
      Kitchen::Provisioner::ChefBase.instance_variable_set(:@enterprise_gem_checked, false)
      Kitchen::Provisioner::ChefBase.instance_variable_set(:@enterprise_gem, nil)
    end

    it "uses standard implementation when no enterprise gem is available" do
      Gem::Specification.singleton_class.any_instance.stubs(:find_by_name).with("kitchen-chef-enterprise").raises(Gem::LoadError)
      Gem::Specification.singleton_class.any_instance.stubs(:find_by_name).with("kitchen-cinc").raises(Gem::LoadError)

      provisioner = Kitchen::Provisioner::ChefTarget.new(config).finalize_config!(instance)
      _(provisioner).must_be_instance_of Kitchen::Provisioner::ChefTarget
    end

    it "falls back to standard implementation when enterprise gem fails to load" do
      mock_spec = stub("gem_spec")
      Gem::Specification.singleton_class.any_instance.stubs(:find_by_name).with("kitchen-chef-enterprise").returns(mock_spec)
      Kitchen::Provisioner::ChefTarget.stubs(:require).raises(LoadError.new("cannot load"))

      provisioner = Kitchen::Provisioner::ChefTarget.new(config).finalize_config!(instance)
      _(provisioner).must_be_instance_of Kitchen::Provisioner::ChefTarget
    end
  end

  describe "overrides" do
    it "fix install_strategy to none" do
      _(provisioner[:install_strategy]).must_equal "none"
    end

    it "force sudo" do
      _(provisioner[:sudo]).must_equal true
    end

    it "remove install_command" do
      _(provisioner.install_command).must_be_empty
    end

    it "remove init_command" do
      _(provisioner.init_command).must_be_empty
    end

    it "remove prepare_command" do
      _(provisioner.prepare_command).must_be_empty
    end
  end

  describe "check_transport" do
    describe "with train transport" do
      let(:connection) { stub(respond_to?: true) }

      it "accepts the transport" do
        _(provisioner.check_transport(connection)).must_equal true
      end
    end

    describe "with non-train transport" do
      let(:connection) { stub(respond_to?: false) }

      it "rejects the transport" do
        _ { provisioner.check_transport(connection) }.must_raise Kitchen::Provisioner::ChefTarget::RequireTrainTransport
      end
    end
  end

  describe "check_local_chef_client" do
    it "must accept >= 19.0.0" do
      provisioner.stubs(:`).returns("Chef Infra Client: 19.0.1\n")
      _(provisioner.check_local_chef_client).must_equal true
    end

    it "must reject < 19.0.0" do
      provisioner.stubs(:`).returns("Chef Infra Client: 18.2.5\n")
      _ { provisioner.check_local_chef_client }.must_raise Kitchen::Provisioner::ChefTarget::ChefVersionTooLow
    end

    it "raises ChefClientNotFound when chef-client is not on PATH" do
      provisioner.stubs(:`).raises(Errno::ENOENT, "No such file or directory - chef-client")

      _ { provisioner.check_local_chef_client }
        .must_raise Kitchen::Provisioner::ChefTarget::ChefClientNotFound
    end
  end

  describe "#kitchen_basepath" do
    it "reads kitchen_root from the driver, which is where Test Kitchen sets it" do
      driver = stub(config: { kitchen_root: "/somewhere/else" })
      instance.stubs(:driver).returns(driver)

      _(provisioner.kitchen_basepath).must_equal "/somewhere/else"
    end
  end

  # Target Mode drives the instance over Train from the workstation, so the
  # transport credentials have to be written out to a file and handed to
  # chef-client. None of that was covered.
  describe "#chef_args" do
    let(:root) { Dir.mktmpdir }

    let(:connection) do
      stub(train_uri: "dummy://coolbeans", credentials_file: "[coolbeans]\nbackend = dummy\n")
    end

    before do
      FileUtils.mkdir_p(File.join(root, ".kitchen"))
      instance.stubs(:remote_exec).returns(connection)
      instance.stubs(:driver).returns(stub(config: { kitchen_root: root }))
      provisioner.stubs(:check_local_chef_client).returns(true)
      config[:root_path] = "/rooty"
    end

    after { FileUtils.remove_entry(root) }

    it "appends the target and credentials flags to the client args" do
      args = provisioner.chef_args("client.rb")

      _(args).must_include "--target coolbeans"
      _(args).must_include "--credentials #{File.join(root, ".kitchen", "coolbeans.ini")}"
    end

    it "keeps the arguments inherited from chef_infra" do
      args = provisioner.chef_args("client.rb")

      _(args).must_include "--config /rooty/client.rb"
      _(args).must_include "--force-formatter"
    end

    it "writes the transport credentials out for chef-client to read" do
      provisioner.chef_args("client.rb")

      credentials = File.join(root, ".kitchen", "coolbeans.ini")
      _(File.file?(credentials)).must_equal true
      _(File.read(credentials)).must_equal "[coolbeans]\nbackend = dummy\n"
    end

    it "rejects a transport that cannot produce a Train URI" do
      instance.stubs(:remote_exec).returns(stub(credentials_file: ""))

      _ { provisioner.chef_args("client.rb") }
        .must_raise Kitchen::Provisioner::ChefTarget::RequireTrainTransport
    end
  end
end
