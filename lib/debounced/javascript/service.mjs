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
    this.sendMessage = this.sendMessage.bind(this);
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
      this.sendMessage(socket, JSON.stringify({ type: 'rejectClient'}));
      socket.destroy();
      return;
    }

    log('DebounceService client connected');
    let connectionBuffer = '';
    this._client = socket;
    socket.on('end', this.onClientDisconnected)
    socket.on('error', this.onConnectionError)
    socket.setEncoding('utf8');
    socket.on('data', data => {
      log('DebounceService data received', data);
      connectionBuffer += data;
      const messages = connectionBuffer.split('\f');
      connectionBuffer = messages.pop();
      messages.forEach(this.handleMessage);
    })
  }

  configureServer() {
    this.server = net.createServer(this.onClientConnected)
    this.server.on('error', (err) => {
      this.handleError(err);
      process.exit(1);
    });
  }

  cleanupDescriptor() {
    if (fs.existsSync(this._socketDescriptor)) {
      log('DebounceEventService removing socket file ', this._socketDescriptor);
      fs.unlinkSync(this._socketDescriptor);
    }
  }

  listen() {
    if (!fs.existsSync(this._socketDescriptor)) {
      this.bind();
      return;
    }

    const probe = net.connect(this._socketDescriptor);
    probe.on('connect', () => {
      probe.destroy();
      log('DebounceEventService another server is listening on', this._socketDescriptor);
      process.exit(1);
    });
    probe.on('error', (err) => {
      if (err.code !== 'ECONNREFUSED') {
        this.handleError(err);
        process.exit(1);
      }
      log('DebounceEventService removing stale socket file ', this._socketDescriptor);
      fs.unlinkSync(this._socketDescriptor);
      this.bind();
    });
  }

  bind() {
    const previousUmask = process.umask(0o177);
    this.server.listen(this._socketDescriptor, () => {
      log('DebounceService listening on', this._socketDescriptor);
      this.cleanupOnExit();
    });
    process.umask(previousUmask);
  }

  cleanupOnExit() {
    process.on('exit', (code) => {
      log(`Process exiting with code: ${code}`);
      this.server.close();
      this.cleanupDescriptor();
    });

    ['SIGTERM', 'SIGINT'].forEach((signal) => {
      process.on(signal, () => {
        log(`Process received ${signal}`);
        process.exit(0);
      });
    });
  }

  sendMessage(socket, message) {
    try {
      socket.write(message);
      socket.write("\f");
    } catch (err) {
      this.handleError(err);
    }
  }

  publishEvent(descriptor, callback) {
    log(`Debounce period expired for ${descriptor} - sending to client`);
    const message = JSON.stringify({
      type: 'publishEvent',
      callback: callback
    });
    this.sendMessage(this._client, message);
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