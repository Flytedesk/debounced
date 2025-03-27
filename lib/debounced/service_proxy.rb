require 'socket'
require 'json'

module Debounced
  ###
  # Ruby interface to the debounce service
  # Input is an activity descriptor, and an object.
  # When the activity is debounced, a callback method is invoked on the object.
  # Assumes the object class has an initializer that accepts a hash of attributes, which are the instance variables
  class ServiceProxy
    DELIMITER = "\f".freeze

    attr_reader :logger, :wait_timeout

    def initialize
      @wait_timeout = Debounced.configuration.wait_timeout
      @logger = Debounced.configuration.logger
      @mutex = Mutex.new
    end

    ###
    # @param [Concurrent::AtomicBoolean] abort_signal set to true to stop listening for messages
    def listen(abort_signal = nil)
      Thread.new do
        receive(abort_signal)
      end
    end

    ###
    # Send message to server to reset its state. Useful for automated testing.
    def reset
      if socket.nil?
        logger.warn("No connection to #{server_name}; unable to reset server.")
      else
        logger.trace { "Resetting #{server_name}" }
        transmit({ type: 'reset' })
      end
    end

    def debounce_activity(activity_descriptor, timeout, callback)
      SemanticLogger.tagged("send") do
        if socket.nil?
          logger.debug { "No connection to #{server_name}; skipping debounce step." }
          callback.call
        else
          logger.trace { "Sending #{activity_descriptor} to #{server_name}" }
          transmit(build_request(activity_descriptor, timeout, callback))
        end
      end
    end

    ###
    # @param [Concurrent::AtomicBoolean] abort_signal set to true to stop listening for messages
    def receive(abort_signal = nil)
      SemanticLogger.tagged("receive") do
        logger.info { "Listening for messages from #{server_name}..." }

        loop do
          break if abort_signal&.true?

          message = receive_message_from_server
          payload = deserialize_message(message)
          next unless payload['type'] == 'publishEvent'

          instantiate_callback(payload['callback']).call
        rescue Debounced::MissingConnectionError => e
          logger.debug e.message
          sleep wait_timeout
        rescue IO::TimeoutError
          # Ignored - normal flow of loop: check abort_signal (L48), get data (L56), timeout waiting for data (69)
          logger.trace {"Timeout waiting for data" }
        end

        close
      end
    rescue StandardError => e
      logger.warn("Unable to listen for messages from #{server_name}: #{e.message}")
      logger.warn(e.backtrace.join("\n"))
    end

    def close
      return unless @socket

      logger.debug("Closing connection to #{server_name}")
      @socket.close
      @socket = nil
    end

    private

    def receive_message_from_server
      raise MissingConnectionError, "Waiting #{wait_timeout}s for #{server_name} to start..." if socket.nil?

      logger.trace { "Waiting for data from #{server_name}..." }
      message = socket.gets(DELIMITER, chomp: true)
      if message.nil?
        close
        raise MissingConnectionError, "#{server_name} ended connection"
      end

      message
    end

    def build_request(descriptor, timeout, callback)
      {
        type: 'debounceEvent',
        data: {
          descriptor:,
          timeout:,
          callback: callback.as_json
        }
      }
    end

    def transmit(message)
      socket.send serialize_message(message), 0
    end

    def server_name
      'DebounceEventServer'
    end

    def serialize_message(message)
      "#{JSON.generate(message)}#{DELIMITER}" # inject EOM delimiter (form feed character)
    end

    def deserialize_message(message)
      logger.trace { "Deserializing #{message}" }
      JSON.parse(message)
    end

    def instantiate_callback(data)
      Callback.parse(data)
    end

    def socket_descriptor
      @socket_descriptor ||= Debounced.configuration.socket_descriptor
    end

    def socket
      @mutex.synchronize do
        return @socket if @socket

        logger.trace { "Connecting to #{server_name} at #{socket_descriptor}" }
        @socket = UNIXSocket.new(socket_descriptor).tap { |s| s.timeout = wait_timeout }
      end
    rescue Errno::ECONNREFUSED, Errno::ENOENT
      ###
      # Errno::ENOENT is raised if the socket file does not exist.
      # Errno::ECONNREFUSED is raised if the socket file exists but no process is listening on it.
      logger.debug { "#{server_name} is not running" }
      nil
    end
  end
end