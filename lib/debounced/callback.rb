require 'debug'

module Debounced
  class Callback

    attr_reader :class_name, :params, :method_name, :method_params
    def initialize(class_name:, params:, method_name:, method_params:)
      @class_name = class_name.to_s
      @params = params || {}
      @method_name = method_name.to_s
      @method_params = method_params || []
    end

    def self.json_create(data)
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
      Object.const_get(class_name)
            .new(**params.transform_keys(&:to_sym))
            .send(method_name, *method_params)
    end
  end
end