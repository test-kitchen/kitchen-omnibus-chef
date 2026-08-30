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

require_relative "../../../spec_helper"
require "kitchen/provisioner/chef/berkshelf"

# Berkshelf is an optional dependency and is not in this gem's Gemfile, so the
# real library is never loadable here. The resolver only reaches for a handful
# of methods on it, which is what this stand-in provides. Without it, #resolve
# and .load! have no coverage at all -- every other spec in the suite stubs
# both of them out wholesale.
describe Kitchen::Provisioner::Chef::Berkshelf do
  let(:null_logger) do
    stub(fatal: nil, error: nil, warn: nil, info: nil, debug: nil, banner: nil)
  end

  let(:berksfile) { "/rooty/Berksfile" }
  let(:path)      { "/tmp/kitchen/cookbooks" }

  describe "#resolve" do
    let(:lockfile)      { stub(present?: true) }
    let(:berksfile_obj) { stub(lockfile: lockfile, update: true, vendor: true) }
    let(:always_update) { false }

    let(:resolver) do
      Kitchen::Provisioner::Chef::Berkshelf.new(
        berksfile, path, logger: null_logger, always_update: always_update
      )
    end

    before do
      fake_ui = Object.new
      fake_ui.define_singleton_method(:mute) { |&block| block.call }

      berksfile_class = Class.new
      berksfile_class.define_singleton_method(:from_file) { |_f| nil }

      stub_const(:Berkshelf, Module.new do
        const_set(:VERSION, "8.0.0")
        const_set(:Berksfile, berksfile_class)
        define_singleton_method(:ui) { fake_ui }
      end)

      ::Berkshelf::Berksfile.stubs(:from_file).with(berksfile).returns(berksfile_obj)
      FileUtils.stubs(:rm_rf)
    end

    after { unstub_const(:Berkshelf) }

    it "vendors the resolved cookbooks into the sandbox" do
      berksfile_obj.expects(:vendor).with(path)

      resolver.resolve
    end

    it "clears the destination first, because Berkshelf requires it to be absent" do
      seq = sequence("vendor")
      FileUtils.expects(:rm_rf).with(path).in_sequence(seq)
      berksfile_obj.expects(:vendor).with(path).in_sequence(seq)

      resolver.resolve
    end

    it "logs the Berkshelf version and the Berksfile in use" do
      null_logger.expects(:info).with(regexp_matches(/Resolving cookbook dependencies with Berkshelf 8\.0\.0/))
      null_logger.expects(:debug).with("Using Berksfile from #{berksfile}")

      resolver.resolve
    end

    it "does not update the lock when always_update is false" do
      berksfile_obj.expects(:update).never

      resolver.resolve
    end

    describe "when always_update is set" do
      let(:always_update) { true }

      it "updates the lock before vendoring" do
        seq = sequence("update")
        berksfile_obj.expects(:update).in_sequence(seq)
        berksfile_obj.expects(:vendor).with(path).in_sequence(seq)

        resolver.resolve
      end

      describe "and there is no lockfile yet" do
        let(:lockfile) { stub(present?: false) }

        it "skips the update" do
          berksfile_obj.expects(:update).never
          berksfile_obj.expects(:vendor).with(path)

          resolver.resolve
        end
      end
    end
  end

  describe ".load!" do
    it "raises a UserError when berkshelf cannot be loaded" do
      Kitchen::Provisioner::Chef::Berkshelf.stubs(:require)
        .with("berkshelf").raises(LoadError, "cannot load such file -- berkshelf")
      null_logger.expects(:fatal)

      err = _ { Kitchen::Provisioner::Chef::Berkshelf.load!(logger: null_logger) }
        .must_raise Kitchen::UserError

      _(err.message).must_match(/Could not load or activate Berkshelf/)
    end
  end

  def stub_const(name, value)
    @stubbed_consts ||= {}
    @stubbed_consts[name] = Object.const_defined?(name) ? Object.const_get(name) : nil
    Object.send(:remove_const, name) if Object.const_defined?(name)
    Object.const_set(name, value)
  end

  def unstub_const(name)
    Object.send(:remove_const, name) if Object.const_defined?(name)
    previous = (@stubbed_consts || {})[name]
    Object.const_set(name, previous) if previous
  end
end
