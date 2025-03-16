require "bundler/setup"
require "debounced"
SemanticLogger.add_appender(io: $stdout)


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each) do |example|
    $logger = SemanticLogger[example.rerun_argument]
    $logger.debug "Starting test: #{example.full_description}"
    example.run
    $logger.debug "Ending test"
  end
end