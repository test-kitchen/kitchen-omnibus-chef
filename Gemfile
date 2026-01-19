source "https://rubygems.org"

gemspec

group :test do
  gem "rake"
  gem "fakefs"
  gem "minitest"
  gem "mocha"
  gem "test-kitchen", git: "https://github.com/test-kitchen/test-kitchen", branch: "remove-chef-provisioner" # TODO: remove once https://github.com/test-kitchen/test-kitchen/pull/2041 is merged
end

group :integration do
  gem "chef-cli"
  gem "kitchen-dokken"
  gem "kitchen-vagrant"
  gem "kitchen-inspec"
end

group :linting do
  gem "cookstyle"
end
