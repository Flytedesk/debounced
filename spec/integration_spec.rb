require 'spec_helper'
require 'pathname'
require 'debounced/abort_signal'
require 'test_event'

RSpec.describe 'Debounced Events', type: :integration do
  DEBOUNCE_TIMEOUT = 1

  def debounce_activity(object)
    @service_proxy.debounce_activity(object.test_id, object, DEBOUNCE_TIMEOUT)
  end

  before :all do
    Debounced.configuration.wait_timeout = 1
  end

  before :each do
    @event_handler_invocations = 0
    allow_any_instance_of(TestEvent).to receive(:publish) { @event_handler_invocations += 1 }
  end

  context 'with server running' do
    before :all do
      gem_path = Pathname.new(Gem::Specification.find_by_name('debounced').gem_dir)
      debounce_event_server_log = File.open(gem_path.join('debounce_server.log'), 'w')
      gem_lib_path = gem_path.join('lib')
      @node_pid = Process.spawn("NODE_ENV=test node #{gem_lib_path}/debounced/javascript/server.mjs",
                                out: debounce_event_server_log,
                                err: debounce_event_server_log)
      Process.detach(@node_pid)
      sleep 0.5 # wait for the server to start

      @event_debouncing_abort_signal = Debounced::AbortSignal.new
      @service_proxy = Debounced::ServiceProxy.new
      @service_proxy.listen(@event_debouncing_abort_signal)
    end

    after :all do
      @event_debouncing_abort_signal.abort
      sleep Debounced.configuration.wait_timeout
      Process.kill('TERM', @node_pid) if @node_pid
    end

    before :each do
      @service_proxy.reset
    end

    context 'and debounce = TRUE' do
      context 'and multiple events are published within the debounce window with the same debounce_key' do
        it 'publishes only the last event' do
          # when
          3.times { debounce_activity(TestEvent.new(test_id: 'test')) }
          # then
          sleep DEBOUNCE_TIMEOUT + 0.5
          expect(@event_handler_invocations).to eq(1)
        end
      end

      context 'and multiple events are published within the debounce window with different debounce_keys' do
        it 'publishes all events' do
          # when
          debounce_activity(TestEvent.new(test_id: 'test1'))
          debounce_activity(TestEvent.new(test_id: 'test2'))
          debounce_activity(TestEvent.new(test_id: 'test3'))
          # then
          sleep DEBOUNCE_TIMEOUT + 0.5
          expect(@event_handler_invocations).to eq(3)
        end
      end

      context 'and multiple events are published outside the debounce window' do
        it 'publishes all events' do
          # when
          3.times do
            debounce_activity(TestEvent.new(test_id: 'test'))
            sleep DEBOUNCE_TIMEOUT + 0.5
          end
          # then
          expect(@event_handler_invocations).to eq(3)
        end
      end
    end
  end

  context 'without server running' do
    it 'publishes all events' do
      # given
      @service_proxy = Debounced::ServiceProxy.new
      # when
      3.times { debounce_activity(TestEvent.new(test_id: 'no-server-test')) }
      # then
      expect(@event_handler_invocations).to eq(3)
    end
  end
end