source "https://rubygems.org"

gemspec development_group: :test
group :test do
  gem "rake"
  gem "fakefs"
  gem "minitest"
  gem "mocha"
  gem "test-kitchen"
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

group :docs do
  gem "yard"
end
