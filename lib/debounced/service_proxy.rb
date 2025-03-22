require 'socket'
require 'json'
require 'json/add/core'
require 'debug'

module Debounced
  ###
  # Ruby interface to the debounce service
  # Input is an activity descriptor, and an object.
  # When the activity is debounced, a callback method is invoked on the object.
  # Assumes the object class has an initializer that accepts a hash of attributes, which are the instance variables
  class ServiceProxy
    DELIMITER = "\f".freeze

    def initialize
      @wait_timeout = Debounced.configuration.wait_timeout
    end

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
      if socket.nil?
        log_debug("No connection to #{server_name}; skipping debounce step.")
        callback.call
      else
        log_debug("Debouncing #{activity_descriptor} to #{server_name}")
        transmit(build_request(activity_descriptor, timeout, callback))
      end
    end

    def receive(abort_signal = nil)
      log_debug("Listening for messages from #{server_name}...")

      loop do
        break if abort_signal&.set?

        if socket.nil?
          log_debug("Waiting for #{server_name} to start...")
          sleep(@wait_timeout)
          next
        end

        log_debug("Waiting for data from #{server_name}...")
        message = socket.gets(DELIMITER, chomp: true)
        if message.nil?
          log_info("Server #{server_name} ended connection")
          close
          break
        end

        log_debug("Received #{message}")
        payload = deserialize_payload(message)
        log_debug("Parsed #{payload}")
        next unless payload['type'] == 'publishEvent'

        instantiate_callback(payload['callback']).call
      rescue IO::TimeoutError
        # Ignored - normal flow of loop: check abort_signal (L48), get data (L56), timeout waiting for data (69)
      end
    rescue StandardError => e
      log_warn("Unable to listen for messages from #{server_name}: #{e.message}")
      log_warn(e.backtrace.join("\n"))
    ensure
    end

    private

    def close
      return unless @socket

      log_info("Closing connection to #{server_name}")
      @socket.close
      @socket = nil
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

    def transmit(request)
      socket.send serialize_payload(request), 0
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
      Callback.json_create(data)
    end

    def socket_descriptor
      @socket_descriptor ||= Debounced.configuration.socket_descriptor
    end

    def socket
      @socket ||= begin
        log_debug("Connecting to #{server_name} at #{socket_descriptor}")
        UNIXSocket.new(socket_descriptor).tap { |s| s.timeout = @wait_timeout }
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