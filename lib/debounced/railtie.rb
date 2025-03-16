require "rails/railtie"

module Debounced
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../../tasks/debounced.rake", __FILE__)
    end
  end
end
