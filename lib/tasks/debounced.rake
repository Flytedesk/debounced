namespace :debounced do
  desc 'Start the debounce server'
  task :server => :environment do
    require 'debounced'

    # Configuration is available because environment is loaded
    socket_descriptor = Debounced.configuration.socket_descriptor

    # Find the gem's JavaScript files
    gem_lib_path = Pathname.new(Gem::Specification.find_by_name('debounced').gem_dir).join('lib')
    js_path = gem_lib_path.join('debounced', 'javascript', 'server.mjs')

    # Exec replaces the current process with the node process
    exec("node #{js_path} #{socket_descriptor}")
  end
end