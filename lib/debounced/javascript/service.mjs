import net from 'net';
import fs from 'fs';

function log(message, ...args) {
  const timestamp = new Date().toISOString();
  console.log(`${timestamp} - ${message}`, ...args);
}

export default class DebounceService {
  constructor(socketDescriptor) {
    this._socketDescriptor = socketDescriptor;
    this._timers = {};
    this._client = null;
    this.publishEvent = this.publishEvent.bind(this);
    this.debounceEvent = this.debounceEvent.bind(this);
    this.reset = this.reset.bind(this);
    this.listen = this.listen.bind(this);
    this.handleError = this.handleError.bind(this);
    this.onClientConnected = this.onClientConnected.bind(this);
    this.onClientDisconnected = this.onClientDisconnected.bind(this);
    this.onConnectionError = this.onConnectionError.bind(this);
    this.handleMessage = this.handleMessage.bind(this);
    this.configureServer();
  }

  onConnectionError(err) {
    log('DebounceService client connection error');
    this._client = null
    this.handleError(err);
  }

  onClientDisconnected() {
    log('DebounceService client disconnected');
    this._client = null
  }

  handleMessage(message) {
    try {
      const object = JSON.parse(message);
      if (object.type === 'debounceEvent') {
        this.debounceEvent(object.data);
      } else if (object.type === 'reset') {
        this.reset();
      } else {
        log('DebounceService unknown message', message);
      }
    } catch (e) {
      log('unable to parse message', e);
    }
  }

  onClientConnected(socket) {
    if (this._client) {
      log('DebounceService rejecting connection: client already connected');
      socket.destroy();
      return;
    }

    log('DebounceService client connected');
    let connectionBuffer = '';
    this._client = socket;
    socket.on('end', this.onClientDisconnected)
    socket.on('error', this.onConnectionError)
    socket.on('data', data => {
      log('DebounceService data received', data.toString());
      connectionBuffer += data.toString();
      const messages = connectionBuffer.split('\f');
      connectionBuffer = ''
      if (!connectionBuffer.endsWith('\f')) {
        connectionBuffer = messages.pop();
      }
      messages.forEach(this.handleMessage);
    })
  }

  configureServer() {
    this.server = net.createServer(this.onClientConnected)
    this.server.on('error', this.handleError);
  }

  listen() {
    // Remove the existing socket file if it exists
    if (fs.existsSync(this._socketDescriptor)) {
      log('DebounceEventService removing stale socket file ', this._socketDescriptor);
      fs.unlinkSync(this._socketDescriptor);
    }

    process.on('exit', (code) => {
      log(`Process exiting with code: ${code}`);
      this.server.close();
    });

    process.on('SIGTERM', () => {
      log('Process received SIGTERM');
      this.server.close();
      process.exit(0);
    });

    process.on('SIGINT', () => {
      log('Process received SIGINT');
      this.server.close();
      process.exit(0);
    });

    this.server.listen(this._socketDescriptor, () => {
      log('DebounceService listening on', this._socketDescriptor);
    });
  }

  publishEvent(descriptor, callback) {
    log(`Debounce period expired for ${descriptor}`);
    const message = JSON.stringify({
      type: 'publishEvent',
      callback: callback
    });

    try {
      this._client.write(message);
      this._client.write("\f");
    } catch (err) {
      this.handleError(err);
    }
  }

  debounceEvent({ descriptor, timeout, callback }) {
    if (this._timers[descriptor]) {
      clearTimeout(this._timers[descriptor]);
    }

    log("Debouncing", descriptor);
    this._timers[descriptor] = setTimeout(() => {
      delete this._timers[descriptor];
      this.publishEvent(descriptor, callback);
    }, timeout * 1000);
  }

  reset() {
    Object.values(this._timers).forEach(timerID => clearTimeout(timerID));
    this._timers = {};
  }

  handleError(err) {
    log('\n\n######\nERROR: ', err);
  }
}