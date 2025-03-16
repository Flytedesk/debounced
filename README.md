# Debounced

A Ruby gem that provides a NodeJS-based event debouncing service for Ruby applications. It uses the JavaScript micro event loop to efficiently debounce events.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'debounced'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install debounced
```

## Dependencies

This gem requires Node.js to be installed on your system, as it uses a Node.js server to handle the debouncing logic. You'll need:

- Node.js >= 14.0.0
- npm (to install the required node packages)

After installing the gem, run:

```bash
$ cd $(bundle show debounced)
$ npm install
```

## Usage

### Configuration

```ruby
# config/initializers/debounced.rb
Debounced.configure do |config|
  config.socket_descriptor = '/tmp/my_app.debounceEvents'
end
```

### Starting the server

You can start the debounce server with:

```bash
$ bundle exec debounced-server
```

Or in your application code:

```ruby
require 'debounced'

# Start the listener thread
proxy = Debounced::ServiceProxy.new
listener_thread = proxy.listen

# Debounce an event
class MyEvent
  attr_reader :attributes

  def initialize(data)
    @attributes = data
  end

  def self.publish(data)
    # Publish logic here
    puts "Publishing event with data: #{data.inspect}"
  end
end

event = MyEvent.new({ id: 1, message: "Hello World" })
proxy.debounce_event("my-event-123", event, 5) # Debounce for 5 seconds
```

## How It Works

1. The gem creates a Unix socket for communication between Ruby and Node.js
2. When you call `debounce_event`, it sends the event to the Node.js server
3. The Node.js server keeps track of events with the same descriptor
4. If another event with the same descriptor arrives before the timeout, it resets the timer
5. When the timeout expires, it sends the event back to Ruby to be published

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).