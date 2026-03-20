const tracer = require('dd-trace');

module.exports = (req, res) => {
  const span = tracer.startSpan('custom.error.operation');
  try {
    throw new Error('Manual span failure!');
  } catch (err) {
    span.setTag('error', true);
    span.setTag('error.message', err.message);
    span.setTag('error.stack', err.stack);
    span.finish();
    res.status(500).send('Error with custom span!');
  }
};
