#!/usr/bin/env node

import DebounceEventService from './service.mjs'
let socketDescriptor = '/tmp/app.debounceEvents';
if (process.argv.length > 2) {
  socketDescriptor = process.argv[2];
}

new DebounceEventService(socketDescriptor).listen();