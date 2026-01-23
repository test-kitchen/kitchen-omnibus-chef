#
# Author:: SAWANOBORI Yukihiko <sawanoboriyu@higanworks.com>)
#
# Copyright (C) 2015, HiganWorks LLC
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

# Usage:
#
# puts your recipes to` apply/` directory.
#
# An example of .kitchen.yml.
#
# ---
# driver:
#   name: vagrant
#
# provisioner:
#   name: chef_apply
#
# platforms:
#   - name: ubuntu-24.04
#   - name: almalinux-10
#
# suites:
#   - name: default
#     run_list:
#       - recipe1
#       - recipe2
#
#
# The chef-apply runs twice below.
#
# chef-apply apply/recipe1.rb
# chef-apply apply/recipe2.rb

require_relative "chef_base"

module Kitchen
  module Provisioner
    # Chef Apply provisioner with enterprise gem delegation support.
    #
    # This provisioner will automatically detect and use kitchen-chef-enterprise
    # or kitchen-cinc if they are installed, providing a seamless upgrade path
    # for enterprise Chef features.
    #
    # @author SAWANOBORI Yukihiko <sawanoboriyu@higanworks.com>
    class ChefApply < ChefBase
      # Factory method that returns the appropriate provisioner implementation.
      # If an enterprise gem (kitchen-chef-enterprise or kitchen-cinc) is available,
      # delegate to its implementation. Otherwise, use the standard implementation.
      #
      # @param config [Hash] configuration hash
      # @return [ChefApply] provisioner instance
      def self.new(config = {})
        enterprise_gem = ChefBase.enterprise_gem_available?

        if enterprise_gem
          begin
            omnibus_chef_class = self
            require "#{enterprise_gem}/provisioner/chef_apply"
            enterprise_class = Kitchen::Provisioner.const_get(:ChefApply)

            if enterprise_class != omnibus_chef_class
              if config[:instance] && config[:instance].respond_to?(:logger)
                config[:instance].logger.info("Using #{enterprise_gem} implementation of ChefApply provisioner")
              end
              return enterprise_class.allocate.tap { |instance| instance.send(:initialize, config) }
            end
          rescue LoadError, NameError => e
            if config[:instance] && config[:instance].respond_to?(:logger)
              config[:instance].logger.debug("Could not load enterprise provisioner, using kitchen-omnibus-chef: #{e.message}")
            end
          end
        end

        allocate.tap { |instance| instance.send(:initialize, config) }
      end

      kitchen_provisioner_api_version 2

      plugin_version Kitchen::VERSION

      default_config :chef_apply_path do |provisioner|
        provisioner
          .remote_path_join(%W{#{provisioner[:chef_omnibus_root]} bin chef-apply})
          .tap { |path| path.concat(".bat") if provisioner.windows_os? }
      end

      default_config :apply_path do |provisioner|
        provisioner.calculate_path("apply")
      end
      expand_path_for :apply_path

      # (see ChefBase#create_sandbox)
      def create_sandbox
        @sandbox_path = Dir.mktmpdir("#{instance.name}-sandbox-")
        File.chmod(0755, sandbox_path)
        info("Preparing files for transfer")
        debug("Creating local sandbox in #{sandbox_path}")

        prepare_json
        prepare(:apply)
      end

      # (see ChefBase#init_command)
      def init_command
        dirs = %w{
          apply
        }.sort.map { |dir| remote_path_join(config[:root_path], dir) }

        vars = if powershell_shell?
                 init_command_vars_for_powershell(dirs)
               else
                 init_command_vars_for_bourne(dirs)
               end

        prefix_command(shell_code_from_file(vars, "chef_base_init_command"))
      end

      # (see ChefSolo#run_command)
      def run_command
        level = config[:log_level]
        lines = []
        config[:run_list].map do |recipe|
          cmd = sudo(config[:chef_apply_path]).dup
            .tap { |str| str.insert(0, "& ") if powershell_shell? }
          args = [
            "apply/#{recipe}.rb",
            "--log_level #{level}",
            "--no-color",
          ]
          args << "--logfile #{config[:log_file]}" if config[:log_file]
          args << "--chef-license #{config[:chef_license]}" if config[:chef_license]

          lines << wrap_shell_code(
            [cmd, *args].join(" ")
            .tap { |str| str.insert(0, reload_ps1_path) if windows_os? }
          )
        end

        prefix_command(lines.join("\n"))
      end
    end
  end
end
