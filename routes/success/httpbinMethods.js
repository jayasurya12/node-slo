// routes/success/httpbinMethods.js
const axios = require('axios');
const tracer = require('dd-trace').init();

module.exports = async (req, res) => {
  const method = req.query.method?.toUpperCase() || 'GET';
  const simulateFail = req.query.fail === 'true';

  const url = simulateFail
    ? `https://httpbin.org/status/500`
    : `https://httpbin.org/${method.toLowerCase()}`;

  const span = tracer.trace(`httpbin.${method.toLowerCase()}`, {
    resource: `httpbin/${method}`,
    tags: {
      'http.target': url,
      'http.method': method,
      'type': 'external',
    }
  });

  try {
    const response = await axios({
      method,
      url,
      data: { sample: 'payload' },
      timeout: 10000
    });

    span.setTag('http.status_code', response.status);
    span.finish();

    res.status(200).json({
      message: `✅ HTTPBIN ${method} request successful`,
      status: response.status
    });
  } catch (err) {
    span.setTag('error', true);
    span.setTag('error.message', err.message);
    span.finish();

    res.status(500).json({
      message: `❌ HTTPBIN ${method} request failed`,
      error: err.message
    });
  }
};
