const dotenv = require('dotenv');
dotenv.config();

// require('dd-trace').init({
//     runtimeMetrics: true,
//     logInjection: true
// });
// require('newrelic');

const express = require('express');
const app = express();
app.use(express.json());

const port = process.env.PORT || 3000;

const { increaseIncoming, getCounts } = require('./utils/counter');
const successRoutes = require('./routes/success');
const errorRoutes = require('./routes/errors');
const externalCalls = require('./routes/external');

// 🔍 Tagging requests with Datadog APM custom tags
app.use((req, res, next) => {
  const span = require('dd-trace').scope().active();
  if (span) {
    span.setTag('http.method', req.method);
    span.setTag('http.route', req.path);
  }
  next();
});

// 🧮 Incoming request count
app.use((req, res, next) => {
  const current = increaseIncoming();
  console.log(`📥 Incoming: ${req.method} ${req.url} | Total: ${current}`);
  next();
});

// 🌐 Homepages
app.get('/', (req, res) => {
  res.send(`
    <h2>Success Routes</h2>
    <ul>
      <li><a href="/success/200">/success/200</a></li>
      <li><a href="/success/201">/success/201</a></li>
      <li><a href="/success/202">/success/202</a></li>
    </ul>
    <h2>Error Routes</h2>
    <ul>
      <li><a href="/error/unhandled">/error/unhandled</a></li>
      <li><a href="/error/handled">/error/handled</a></li>
      <li><a href="/error/async">/error/async</a></li>
      <li><a href="/error/custom-span">/error/custom-span</a></li>
      <li>POST to <code>/error/json</code> with invalid JSON using curl</li>
    </ul>
  `);
});

// 🐢 Slow Route
app.get('/slow/timeout', require('./routes/slow/timeout'));

// ✅ Success Routes
app.get('/success/accepted', successRoutes.accepted);
app.get('/success/delete', successRoutes.delete);
app.post('/success/post', successRoutes.post);
app.put('/success/update', successRoutes.put);

// 🌐 External Routes
app.get('/outgoing/httpbin', externalCalls.httpbin);

// ❌ Error Routes
app.get('/error/unhandled', errorRoutes.unhandled);
app.get('/error/handled', errorRoutes.handled);
app.get('/error/async', errorRoutes.async);
app.get('/error/custom-span', errorRoutes.customSpan);
app.get('/error/deleteFail', errorRoutes.deleteFail);
app.get('/error/updateFail', errorRoutes.updateFail);
app.post('/error/json', errorRoutes.json, (req, res) => {
  res.send('Valid JSON received');
});

// 📊 Metrics Route
app.get('/metrics', (req, res) => {
  res.json(getCounts());
});

// ⛔️ 404 Handler
app.use((req, res, next) => {
  console.warn(`🚫 404 Not Found: ${req.method} ${req.url}`);
  res.status(404).send('404 - Route Not Found');
});

// 💥 Global Error Handler
app.use((err, req, res, next) => {
  console.error(`❌ Error in ${req.method} ${req.url} →`, err.message);
  res.status(500).send('Caught by global error handler');
});

// 🚀 Server Start
app.listen(port, () => {
  console.log(`✅ App listening at http://localhost:${port}`);
});
