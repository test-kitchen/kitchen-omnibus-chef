#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2012, Fletcher Nichol
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

gem "minitest"

require "fakefs/safe"
require "minitest/autorun"
require "mocha/minitest"

# Require the base test-kitchen gem which provides Kitchen module infrastructure
begin
  require "chef-test-kitchen-enterprise"
rescue LoadError
  # If not available, try the standard test-kitchen gem
  require "kitchen"
end

# These specs never install anything or talk to a Chef Infra Server.
# Everything this gem does is turn configuration into shell commands, sandbox
# directories, and client.rb/solo.rb files, so all of it can be exercised as
# pure string and filesystem work. Anything that genuinely needs a converge
# belongs in the Test Kitchen integration suites -- see CONTRIBUTING.md.
Mocha.configure do |config|
  # Fail if an example stubs a method the real object does not have. Without
  # this, a rename in lib/ leaves the specs stubbing a method that no longer
  # exists and passing while the provisioner is broken.
  config.stubbing_non_existent_method = :prevent
end

# @return [Boolean] whether the suite is running on Windows
def running_tests_on_windows?
  ENV["OS"] == "Windows_NT"
end

# Roots an absolute path on the current drive so path assertions work on
# Windows, where "/rooty" alone is not absolute.
#
# @param root_path [String] a Unix-style absolute path
# @return [String] the same path, drive-qualified on Windows
def os_safe_root_path(root_path)
  if running_tests_on_windows?
    File.join(Dir.pwd[0..1], root_path).to_s
  else
    root_path
  end
end
