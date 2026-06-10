module Debounced

  ###
  # Represents a callback to be executed by the debounce service
  class Callback
    attr_accessor :class_name, :method_name, :args, :kwargs, :method_args, :method_kwargs

    ###
    # @param [String] class_name the name of the class that will receive the callback
    # @param [String] method_name the name of the method that will be called
    # @param [Array] args positional arguments passed to the static method, or to the initializer for instance methods (optional)
    # @param [Hash] kwargs keyword arguments passed to the static method, or to the initializer for instance methods (optional)
    # @param [Array] method_args positional arguments passed to the instance method (optional, ignored for static methods)
    # @param [Hash] method_kwargs keyword arguments passed to the instance method (optional, ignored for static methods)
    #
    # @note if the class implements the method_name as a class method, the message will be sent to the class with args and kwargs.
    # otherwise, an instance of the class will be created using args and kwargs, and the message will be sent to the instance
    # with method_args and method_kwargs.
    def initialize(class_name:, method_name:, args: [], kwargs: {}, method_args: [], method_kwargs: {})
      @class_name = class_name.to_s
      @method_name = method_name.to_s
      @args = args
      @kwargs = kwargs
      @method_args = method_args
      @method_kwargs = method_kwargs
    end

    def self.parse(data)
      new(
        class_name: data['class_name'],
        method_name: data['method_name'],
        args: data['args'],
        kwargs: data['kwargs'].transform_keys(&:to_sym),
        method_args: data.fetch('method_args', []),
        method_kwargs: (data['method_kwargs'] || {}).transform_keys(&:to_sym),
      )
    end

    def as_json
      {
        class_name:,
        method_name:,
        args:,
        kwargs:,
        method_args:,
        method_kwargs:,
      }
    end

    def call
      Debounced.configuration.logger.debug("Invoking callback #{method_name}")
      klass = Object.const_get(class_name)
      if klass.respond_to?(method_name)
        klass.send(method_name, *args, **kwargs)
      else
        instance = klass.new(*args, **kwargs)
        instance.send(method_name, *method_args, **method_kwargs)
      end
    rescue StandardError => e
      Debounced.configuration.logger.warn("Unable to invoke callback #{as_json}: #{e.message}")
      Debounced.configuration.logger.warn(e.backtrace.join("\n"))
    end
  end
end