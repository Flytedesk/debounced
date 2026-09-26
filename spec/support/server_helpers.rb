require 'socket'
require 'timeout'

module ServerHelpers
  SERVER_SCRIPT = File.expand_path('../../lib/debounced/javascript/server.mjs', __dir__)

  def start_server(socket_path)
    pid = spawn_server(socket_path)
    Timeout.timeout(5) { sleep 0.05 until File.socket?(socket_path) }
    pid
  end

  def spawn_server(socket_path)
    log = File.open('debounce_server.log', 'a')
    Process.spawn('node', SERVER_SCRIPT, socket_path, out: log, err: log)
  end

  def stop_server(pid)
    Process.kill('TERM', pid)
    Process.wait(pid)
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  end

  def exit_status(pid, within:)
    deadline = Time.now + within
    until Time.now > deadline
      _, status = Process.wait2(pid, Process::WNOHANG)
      return status if status

      sleep 0.05
    end
  end

  def wait_until_accepting(socket_path)
    Timeout.timeout(5) do
      UNIXSocket.new(socket_path).close
    rescue Errno::ENOENT, Errno::ECONNREFUSED
      sleep 0.05
      retry
    end
  end

  def write_message(connection, message)
    connection.write(JSON.generate(message), Debounced::ServiceProxy::DELIMITER)
  end

  def read_message(connection, timeout: 2)
    return unless connection.wait_readable(timeout)

    line = connection.gets(Debounced::ServiceProxy::DELIMITER, chomp: true)
    line && JSON.parse(line)
  end

  def debounce_message(descriptor, timeout: 0.1, kwargs: {})
    {
      type: 'debounceEvent',
      data: {
        descriptor:,
        timeout:,
        callback: { class_name: 'TestEvent', method_name: 'publish1', kwargs: }
      }
    }
  end
end
