// routes/success/httpbinCall.js
const axios = require('axios');
// const tracer = require('dd-trace').init(); // Make sure init is only once in app.js

module.exports = async (req, res) => {
  const randomDelay = Math.floor(Math.random() * 10) + 1; // Delay between 1s and 10s
  const url = `https://httpbin.org/delay/${randomDelay}`;

  // const span = tracer.trace('httpbin.request', {
  //   resource: `httpbin/delay/${randomDelay}`,
  //   tags: {
  //     'http.target': url,
  //     'type': 'external',
  //     'endpoint': '/delay/:seconds'
  //   }
  // });

  try {
    const response = await axios.get(url);
    span.setTag('http.status_code', response.status);
    span.setTag('delay.seconds', randomDelay);
    span.finish();

    res.status(200).send(`✅ Fetched httpbin with ${randomDelay}s delay. Status: ${response.status}`);
  } catch (err) {
    span.setTag('error', true);
    span.setTag('error.message', err.message);
    span.finish();

    res.status(500).send('❌ Failed to reach httpbin');
  }
};
