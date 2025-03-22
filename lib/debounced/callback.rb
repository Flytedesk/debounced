module Debounced

  ###
  # Represents a callback to be executed by the debounce service
  class Callback
    attr_accessor :class_name, :method_name, :args, :kwargs

    ###
    # @param [String] class_name the name of the class that will receive the callback
    # @param [String] method_name the name of the method that will be called
    # @param [Array] args the positional arguments to be passed to the method (optional)
    # @param [Hash] kwargs the keyword arguments to be passed to the method (optional)
    #
    # @note if the class implements the method_name, the message will be sent to the class with the args and kwargs.
    # otherwise, an instance of the class will be created and the message will be sent to the instance. in this case,
    # the args and kwargs will be passed to the initializer.
    def initialize(class_name:, method_name:, args: [], kwargs: {})
      @class_name = class_name.to_s
      @method_name = method_name.to_s
      @args = args
      @kwargs = kwargs
    end

    def self.parse(data)
      new(
        class_name: data['class_name'],
        method_name: data['method_name'],
        args: data['args'],
        kwargs: data['kwargs'].transform_keys(&:to_sym),
      )
    end

    def as_json
      {
        class_name:,
        method_name:,
        args:,
        kwargs:,
      }
    end

    def call
      klass = Object.const_get(class_name)
      if klass.respond_to?(method_name)
        klass.send(method_name, *args, **kwargs)
      else
        instance = klass.new(*args, **kwargs)
        instance.send(method_name)
      end
    end

  end
end