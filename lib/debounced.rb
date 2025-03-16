require 'debounced/version'
require 'debounced/railtie' if defined?(Rails)
require 'debounced/service_proxy'
require 'semantic_logger'

module Debounced
  class Error < StandardError; end
  
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  class Configuration
    attr_accessor :socket_descriptor, :wait_timeout, :callback_method, :logger

    def initialize
      @socket_descriptor = ENV['DEBOUNCED_SOCKET'] || '/tmp/app.debounceEvents'
      @wait_timeout = ENV['DEBOUNCED_TIMEOUT']&.to_i || 3
      @callback_method = :publish
      SemanticLogger.add_appender(file_name: 'debounced_proxy.log', formatter: :color)
      SemanticLogger.default_level = ENV.fetch('LOG_LEVEL', 'info')
      @logger = SemanticLogger['ServiceProxy']
    end
  end
end