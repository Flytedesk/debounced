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

    attr_reader :mutex
    def initialize
      @wait_timeout = Debounced.configuration.wait_timeout
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
        log_debug("No connection to #{server_name}; unable to reset server.")
      else
        log_debug("Resetting #{server_name}")
        transmit({ type: 'reset' })
      end
    end

    def debounce_activity(activity_descriptor, timeout, callback)
      SemanticLogger.tagged("send") do
        log_debug("#debounce_activity")
        if socket.nil?
          log_debug("No connection to #{server_name}; skipping debounce step.")
          callback.call
        else
          log_debug("Sending #{activity_descriptor} to #{server_name}")
          transmit(build_request(activity_descriptor, timeout, callback))
        end
      end
    end

    ###
    # @param [Concurrent::AtomicBoolean] abort_signal set to true to stop listening for messages
    def receive(abort_signal = nil)
      SemanticLogger.tagged("receive") do
        log_debug("Listening for messages from #{server_name}...")

        loop do
          break if abort_signal&.true?

          if socket.nil?
            log_debug("Waiting #{@wait_timeout}s for #{server_name} to start...")
            sleep(@wait_timeout)
            next
          end

          log_debug("Waiting for data from #{server_name}...")
          message = nil
          socket do |s|
            message = s.gets(DELIMITER, chomp: true)
          end

          if message.nil?
            log_info("#{server_name} ended connection")
            close
            sleep(@wait_timeout)
            next
          end

          log_debug("Received #{message}")
          payload = deserialize_payload(message)
          log_debug("Parsed #{payload}")
          next unless payload['type'] == 'publishEvent'

          instantiate_callback(payload['callback']).call
        rescue IO::TimeoutError
          # Ignored - normal flow of loop: check abort_signal (L48), get data (L56), timeout waiting for data (69)
          log_debug("Timeout waiting for data")
        end
        close
        log_debug("Ending receive loop#{abort_signal&.true? ? ' with abort signal' : ''}")
      end
    rescue StandardError => e
      log_warn("Unable to listen for messages from #{server_name}: #{e.message}")
      log_warn(e.backtrace.join("\n"))
    end

    def close
      @mutex.synchronize do
        return unless @socket

        log_info("Closing connection to #{server_name}")
        @socket.close
        @socket = nil
      end
    end

    private

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

    def transmit(request)
      socket do |s|
        s.send serialize_payload(request), 0
      end
    end

    def server_name
      'DebounceEventServer'
    end

    def serialize_payload(payload)
      "#{JSON.generate(payload)}#{DELIMITER}" # inject EOM delimiter (form feed character)
    end

    def deserialize_payload(payload)
      JSON.parse(payload)
    end

    def instantiate_callback(data)
      Callback.parse(data)
    end

    def socket_descriptor
      @socket_descriptor ||= Debounced.configuration.socket_descriptor
    end

    def socket(&block)
      @mutex.synchronize do
        unless @socket
          log_debug("Connecting to #{server_name} at #{socket_descriptor}")
          @socket = UNIXSocket.new(socket_descriptor).tap { |s| s.timeout = @wait_timeout }
        end

        if @socket && block_given?
          block.call(@socket)
        end

        @socket
      end
    rescue Errno::ECONNREFUSED, Errno::ENOENT
      ###
      # Errno::ENOENT is raised if the socket file does not exist.
      # Errno::ECONNREFUSED is raised if the socket file exists but no process is listening on it.
      log_debug("#{server_name} is not running")
      nil
    end
    
    def log_debug(message)
      Debounced.configuration.logger.debug { message }
    end
    
    def log_info(message)
      Debounced.configuration.logger.info(message)
    end
    
    def log_warn(message)
      Debounced.configuration.logger.warn(message)
    end
  end
end