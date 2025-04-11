require "bundler/setup"
require "debounced"

if ENV['LOG_TO_STDOUT'] == 'true'
  SemanticLogger.add_appender(io: $stdout)
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each) do |example|
    $logger = Debounced.configuration.logger
    $logger.info "Starting test: #{example.full_description}"
    example.run
    $logger.info "Ending test"
  end
end