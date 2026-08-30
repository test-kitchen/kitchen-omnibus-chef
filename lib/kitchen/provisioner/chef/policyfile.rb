#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2013, Fletcher Nichol
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

require "shellwords" unless defined?(Shellwords)
require "rbconfig" unless defined?(RbConfig)

require "kitchen/errors"
require "kitchen/logging"
require "kitchen/shell_out"
require "kitchen/which"

module Kitchen
  module Provisioner
    module Chef
      # Chef cookbook resolver that uses Policyfiles to calculate dependencies.
      #
      # @author Fletcher Nichol <fnichol@nichol.ca>
      class Policyfile
        include Logging
        include ShellOut
        include Which

        # Creates a new cookbook resolver.
        #
        # @param policyfile [String] path to a Policyfile
        # @param path [String] path in which to vendor the resulting
        #   cookbooks
        # @param license [String, nil] a Chef license acceptance value passed
        #   through to the CLI as `--chef-license`; nil or empty passes nothing
        # @param logger [Kitchen::Logger] a logger to use for output, defaults
        #   to `Kitchen.logger`
        # @param always_update [Boolean] when true, run `chef update` after
        #   `chef install` so the policy lock is refreshed
        # @param policy_group [String, nil] the policy group to export; nil
        #   omits `--policy_group`, which leaves the CLI on its "local" default
        def initialize(policyfile, path, license: nil, logger: Kitchen.logger, always_update: false, policy_group: nil)
          @policyfile    = policyfile
          @path          = path
          @logger        = logger
          @always_update = always_update
          @policy_group  = policy_group
          @license       = license
        end

        # Loads the library code required to use the resolver.
        #
        # Deliberately a no-op: this resolver shells out to the `chef-cli`
        # executable and so has no library to require. It exists to match
        # {Berkshelf.load!}, which the provisioners call interchangeably.
        #
        # @param logger [Kitchen::Logger] a logger to use for output, defaults
        #   to `Kitchen.logger`
        # @return [void]
        def self.load!(logger: Kitchen.logger)
          # intentionally left blank
        end

        # Performs the cookbook resolution and vendors the resulting cookbooks
        # in the desired path, by shelling out to `chef export`.
        #
        # @return [String] the standard output of the `chef export` run
        # @raise [Kitchen::UserError] if no `chef` or `chef-cli` executable is
        #   on the PATH
        # @raise [Kitchen::ShellOut::ShellCommandFailed] if the export fails
        def resolve
          if policy_group
            info("Exporting cookbook dependencies from Policyfile #{path} with policy_group #{policy_group} using `#{cli_path} export`...")
            run_command("#{cli_path} export #{escape_path(policyfile)} #{escape_path(path)} --policy_group #{policy_group} --force #{chef_license(license)}")
          else
            info("Exporting cookbook dependencies from Policyfile #{path} using `#{cli_path} export`...")
            run_command("#{cli_path} export #{escape_path(policyfile)} #{escape_path(path)} --force #{chef_license(license)}")
          end
        end

        # Runs `chef install` to determine the correct cookbook set and
        # generate the policyfile lock, followed by `chef update` when
        # {#always_update} is set.
        #
        # @return [void]
        # @raise [Kitchen::UserError] if no `chef` or `chef-cli` executable is
        #   on the PATH
        # @raise [Kitchen::ShellOut::ShellCommandFailed] if either run fails
        def compile
          if File.exist?(lockfile)
            info("Installing cookbooks for Policyfile #{policyfile} using `#{cli_path} install`")
          else
            info("Policy lock file doesn't exist, running `#{cli_path} install` for Policyfile #{policyfile}...")
          end
          run_command("#{cli_path} install #{escape_path(policyfile)} #{chef_license(license)}")

          if always_update
            info("Updating policy lock using `#{cli_path} update`")
            run_command("#{cli_path} update #{escape_path(policyfile)} #{chef_license(license)}")
          end
        end

        # Return the path to the lockfile corresponding to this policyfile.
        #
        # @return [String]
        def lockfile
          policyfile.gsub(/\.rb\Z/, ".lock.json")
        end

        private

        # @return [String] path to a Policyfile
        # @api private
        attr_reader :policyfile

        # @return [String] path in which to vendor the resulting cookbooks
        # @api private
        attr_reader :path

        # @return [Kitchen::Logger] a logger to use for output
        # @api private
        attr_reader :logger

        # @return [Boolean] If true, always update cookbooks in the policy.
        # @api private
        attr_reader :always_update

        # @return [String] name of the policy_group, nil results in "local"
        # @api private
        attr_reader :policy_group

        # @return [String] name of the chef_license
        # @api private
        attr_reader :license

        # Escape spaces in a path in way that works with both Sh (Unix) and
        # Windows.
        #
        # @param path [String] Path to escape
        # @return [String]
        # @api private
        def escape_path(path)
          if /mswin|mingw/.match?(RbConfig::CONFIG["host_os"])
            # I know what you're thinking: "just use Shellwords.escape". That
            # method produces incorrect results on Windows with certain input
            # which would be a metacharacter in Sh but is not for one or more of
            # Windows command line parsing libraries. This covers the 99% case of
            # spaces in the path without breaking other stuff.
            if /[ \t\n\v"]/.match?(path)
              "\"#{path.gsub(/[ \t\n\v\"\\]/) { |m| "\\" + m[0] }}\""
            else
              path
            end
          else
            Shellwords.escape(path)
          end
        end

        # Find the `chef` or `chef-cli` commands in the path or raise `chef` is present in
        # ChefDK / Workstation releases, but is no longer shipped in any gems now that we
        # use a Go based wrapper for the `chef` command in Workstation. The Ruby CLI has been
        # renamed `chef-cli` under the hood and is shipped in the `chef-cli` gem.
        #
        # @api private
        # @return [String]
        def cli_path
          @cli_path ||= which("chef-cli") || which("chef") || no_cli_found_error
        end

        # Logs an explanation and aborts because neither CLI could be found.
        #
        # @return [void] never returns normally
        # @raise [Kitchen::UserError] always
        # @api private
        def no_cli_found_error
          @logger.fatal("The `chef` or `chef-cli` executables cannot be found in your " \
                        "PATH. Ensure you have installed Chef Workstation " \
                        "from https://www.chef.io/downloads/ and that your PATH " \
                        "setting includes the path to the `chef` or `chef-cli` commands.")
          raise UserError, "Could not find the chef or chef-cli executables in your PATH."
        end

        # Builds the `--chef-license` flag for a CLI invocation.
        #
        # @param license [String, nil] the license acceptance value
        # @return [String] `"--chef-license <value>"`, or the empty string when
        #   `license` is nil or empty
        # @api private
        def chef_license(license)
          (license.nil? || license.empty?) ? "" : "--chef-license #{license}"
        end

      end
    end
  end
end
