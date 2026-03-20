// ⚠️ APM agents MUST be initialized before any other require
require('dd-trace').init({
  runtimeMetrics: true,
  logInjection: true,
});
require('newrelic');

const dotenv = require('dotenv');
dotenv.config();

const express = require('express');
const app = express();
app.use(express.json());

const port = process.env.PORT || 3000;

const { increaseIncoming, getCounts } = require('./utils/counter');
const successRoutes = require('./routes/success');
const errorRoutes = require('./routes/errors');
const externalCalls = require('./routes/external');

// Incoming request count
app.use((req, res, next) => {
  const current = increaseIncoming();
  console.log(`📥 Incoming: ${req.method} ${req.url} | Total: ${current}`);
  next();
});

// Homepages
app.get('/', (req, res) => {
  res.send(`
    <h1>🚀 SLO Testing Application</h1>
    <p>Enterprise-grade Node.js app for testing SLO/SLI with Datadog, New Relic, and Atatus</p>

    <h2>✅ Success Routes</h2>
    <ul>
      <li><a href="/success/200">/success/200</a> - GET success with JSON response</li>
      <li><a href="/success/accepted">/success/accepted</a> - 202 Accepted</li>
      <li><a href="/success/delete">/success/delete</a> - DELETE success</li>
      <li>POST <code>/success/post</code> - Create resource (201)</li>
      <li>PUT <code>/success/update</code> - Update resource (200)</li>
    </ul>

    <h2>❌ Error Routes</h2>
    <ul>
      <li><a href="/error/unhandled">/error/unhandled</a> - Throws unhandled exception</li>
      <li><a href="/error/handled">/error/handled</a> - Returns 500 error</li>
      <li><a href="/error/async">/error/async> - Async Promise rejection</li>
      <li><a href="/error/custom-span">/error/custom-span</a> - Custom Datadog span error</li>
      <li><a href="/error/deleteFail">/error/deleteFail</a> - DELETE failure</li>
      <li><a href="/error/updateFail">/error/updateFail</a> - PUT failure</li>
      <li>POST <code>/error/json</code> with invalid JSON - JSON parse error</li>
    </ul>

    <h2>🌐 External & Slow Routes</h2>
    <ul>
      <li><a href="/outgoing/httpbin">/outgoing/httpbin</a> - External HTTP call to httpbin.org</li>
      <li><a href="/outgoing/httpbin?fail=true">/outgoing/httpbin?fail=true</a> - Simulated external failure</li>
      <li><a href="/slow/timeout">/slow/timeout</a> - 2-minute delay (timeout test)</li>
    </ul>

    <h2>📊 Monitoring Endpoints</h2>
    <ul>
      <li><a href="/health">/health</a> - Health check (liveness probe)</li>
      <li><a href="/ready">/ready</a> - Readiness check</li>
      <li><a href="/metrics">/metrics</a> - Request counters</li>
    </ul>
  `);
});

// Slow Route
app.get('/slow/timeout', require('./routes/slow/timeout'));

// Success Routes
app.get('/success/200', successRoutes.get200);
app.get('/success/accepted', successRoutes.accepted);
app.get('/success/delete', successRoutes.delete);
app.post('/success/post', successRoutes.post);
app.put('/success/update', successRoutes.put);

// External Routes
app.get('/outgoing/httpbin', externalCalls.httpbin);

// JSON Parse Error Route
app.post('/error/json', (req, res) => {
  res.status(200).json({ message: 'Valid JSON received', body: req.body });
});

// Error Routes
app.get('/error/unhandled', errorRoutes.unhandled);
app.get('/error/handled', errorRoutes.handled);
app.get('/error/async', errorRoutes.async);
app.get('/error/custom-span', errorRoutes.customSpan);
app.get('/error/deleteFail', errorRoutes.deleteFail);
app.get('/error/updateFail', errorRoutes.updateFail);

// Metrics Route
app.get('/metrics', (req, res) => {
  res.json(getCounts());
});

// Health Check Endpoints
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.env.DD_VERSION || '1.0.0'
  });
});

app.get('/ready', (req, res) => {
  res.status(200).json({
    status: 'ready',
    timestamp: new Date().toISOString(),
    checks: {
      server: 'up',
      memory: process.memoryUsage().heapUsed < 500 * 1024 * 1024 ? 'ok' : 'critical'
    }
  });
});

// 404 Handler
app.use((req, res, next) => {
  console.warn(`🚫 404 Not Found: ${req.method} ${req.url}`);
  res.status(404).send('404 - Route Not Found');
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error(`❌ Error in ${req.method} ${req.url} →`, err.message);
  res.status(500).send('Caught by global error handler');
});

// Server Start
app.listen(port, () => {
  console.log(`✅ App listening at http://localhost:${port}`);
});
