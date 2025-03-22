# Debounced

Efficient debouncing mechanism for Ruby events. Use it for rate limiting, deduplication, or other 
scenarios where you want to wait for a certain amount of time before processing a given event.

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

- Node.js >= 20.0.0

## Usage

### Configuration

```ruby
# config/initializers/debounced.rb
Debounced.configure do |config|
  config.socket_descriptor = '/tmp/my_app.debounceEvents'
  config.wait_timeout = 3 # idle timeout in seconds for a given activity descriptor
end
```

### Starting the server

Start the nodeJS debounce server with:

```bash
$ bundle exec debounced:server
```

In your Ruby application code:

```ruby
require 'debounced'

# Start a background thread to receive notification that events are ready to be handled after debounce wait is complete
proxy = Debounced::ServiceProxy.new
proxy.listen

# Define your event class; create a helper method that will produce a Debounced::Callback object, which 
# is used to notify the server that the event is ready to be handled
class MyEvent
  attr_reader :test_id

  def initialize(test_id:)
    @test_id = test_id
  end

  def publish
    # put logic here to publish the event after debouncing
    puts "Publishing event: #{inspect}"
  end
  
  def debounce_callback
    Debounced::Callback.new(
      class_name: self.class.name,
      params: { test_id: },
      method_name: 'publish',
      method_params: []
    )
  end
end

event = MyEvent.new({ test_id: "Hello World" })

# request the server to debounce the event, ignoring it if another event with the 
# same descriptor arrives before the timeout
proxy.debounce_activity("my-event-123", 5, event.debounce_callback)
# 2 seconds later
proxy.debounce_activity("my-event-123", 5, event.debounce_callback)
# 4 seconds later
proxy.debounce_activity("my-event-123", 5, event.debounce_callback)
# 5 seconds later the event is published!
# > Publishing event: #<MyEvent:0x00007f9b1b8b3b40 @test_id="Hello World">
```

## How It Works

1. The gem creates a Unix socket for communication between Ruby and Node.js
2. When you call `debounce_activity`, it sends the event to the Node.js server
3. The Node.js server restarts a timer every time an event with a given activity_descriptor is received
4. When the timeout expires, it sends the event back to Ruby to be published

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).