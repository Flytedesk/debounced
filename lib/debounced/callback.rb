require 'debug'

module Debounced
  class Callback

    attr_accessor :class_name, :params, :method_name, :method_params

    ###
    # Create a new callback object
    # @param class_name [String] the name of the class to call the method on
    # @param params [Hash] a hash of parameters to pass to the class initializer (optional)
    # @param method_name [String] the name of the method to call.
    #   If the method is a class method, it should be prefixed with a "."
    #   If it is an instance method, it should be prefixed with a "#"
    # @param method_params [Array] an array of parameters to pass to the method
    # @return [Debounced::Callback]
    # @note @params is ignored if the method is a class method
    def initialize(class_name:, params:, method_name:, method_params:)
      @class_name = class_name.to_s
      @params = params || {}
      @method_name = method_name.to_s
      @method_params = method_params || []
    end

    def self.parse(data)
      new(
        class_name: data['class_name'],
        params: data['params'],
        method_name: data['method_name'],
        method_params: data['method_params']
      )
    end

    def as_json
      {
        class_name:,
        params:,
        method_name:,
        method_params:
      }
    end

    def call
      klass = Object.const_get(class_name)
      message = method_name[1..-1] # strip of method_name prefix, either "." or "#"
      target = klass
      if method_name[0] == '#'
        target = klass.new(**params.transform_keys(&:to_sym))
      end
      target.send(message, *method_params)
    end

  end
end