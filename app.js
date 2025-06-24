require('dd-trace').init();
const express = require('express');
const app = express();
const dotenv = require('dotenv');
dotenv.config();
const port = process.env.PORT || 3000;

const { increaseIncoming, getCounts } = require('./utils/counter');
const successRoutes = require('./routes/success');
const errorRoutes = require('./routes/errors');

// Middleware
app.use(express.json());
app.use((req, res, next) => {
  const current = increaseIncoming();
  console.log(`📥 Incoming: ${req.method} ${req.url} | Total: ${current}`);
  next();
});

// Homepage
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

// slow
app.get('/slow/timeout', require('./routes/slow/timeout'));

// Success Routes
app.get('/success/200', successRoutes.ok);
app.get('/success/201', successRoutes.created);
app.get('/success/202', successRoutes.accepted);
app.get('/success/outgoing', successRoutes.outgoing);
app.get('/outgoing/httpbin', successRoutes.httpbinMethods);


// Error Routes
app.get('/error/unhandled', errorRoutes.unhandled);
app.get('/error/handled', errorRoutes.handled);
app.get('/error/async', errorRoutes.async);
app.get('/error/custom-span', errorRoutes.customSpan);
app.post('/error/json', errorRoutes.json, (req, res) => {
  res.send('Valid JSON received');
});

// Metrics Route
app.get('/metrics', (req, res) => {
  res.json(getCounts());
});

// ⛔️ 404 Handler – PLACE THIS JUST BEFORE THE GLOBAL ERROR HANDLER
app.use((req, res, next) => {
  console.warn(`🚫 404 Not Found: ${req.method} ${req.url}`);
  res.status(404).send('404 - Route Not Found');
});

// 💥 Global Error Handler
app.use((err, req, res, next) => {
  console.error(`❌ Error in ${req.method} ${req.url} →`, err.message);
  res.status(500).send('Caught by global error handler');
});

// Server Start
app.listen(port, () => {
  console.log(`✅ App listening at http://localhost:${port}`);
});
