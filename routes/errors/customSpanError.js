// const tracer = require('dd-trace').init();

module.exports = (req, res) => {
  // const span = tracer.startSpan('custom.operation');
  try {
    throw new Error('Manual span failure!');
  } catch (err) {
    span.setTag('error', err);
    span.finish();
    res.status(500).send('Error with custom span!');
  }
};
