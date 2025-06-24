require('./dd-tracer'); // Start Datadog tracing

const express = require('express');
const app = express();
const port = 3000;

// Simulated endpoint with random success/failure
app.get('/api/check', (req, res) => {
  const isSuccess = Math.random() > 0.3; // 70% chance of success
  if (isSuccess) {
    res.status(200).send('✅ Success');
  } else {
    res.status(500).send('❌ Error occurred');
  }
});

// Healthcheck
app.get('/', (req, res) => {
  res.send('Node APM Demo is running');
});

app.listen(port, () => {
  console.log(`🚀 App running at http://localhost:${port}`);
});
