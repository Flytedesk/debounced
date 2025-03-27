require_relative "lib/debounced/version"

Gem::Specification.new do |gem|
  gem.name = "debounced"
  gem.version = Debounced::VERSION
  gem.authors = ["Gary Passero"]
  gem.email = ["gary@flytedesk.com"]

  gem.summary = "Efficient event debouncing in Ruby"
  gem.description = "Leverage JavaScript micro-event loop to debounce events in Ruby applications"
  gem.homepage = "https://github.com/flytedesk/debounced"
  gem.license = "MIT"
  gem.required_ruby_version = ">= 3.0.0"

  gem.metadata["source_code_uri"] = gem.homepage
  gem.metadata["changelog_uri"] = "#{gem.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  gem.files = Dir.glob("{lib,exe}/**/*") + %w[README.md CHANGELOG.md]
  gem.require_paths = ["lib"]

  # # Dependencies
  gem.add_dependency "json", "~> 2.10.2"
  gem.add_dependency "semantic_logger", "~> 4.15.0"
  gem.add_dependency 'logger'

  # Development dependencies
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "debug", "~> 1.0", ">= 1.0.0"
end