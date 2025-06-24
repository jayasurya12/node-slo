const tracer = require('dd-trace').init({
  service: 'node-apm-demo',
  env: process.env.DD_ENV || 'dev',
  logInjection: true,
  analytics: true,
  runtimeMetrics: true,
  logLevel: 'debug'
});

module.exports = tracer;
