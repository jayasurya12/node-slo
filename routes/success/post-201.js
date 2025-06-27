const logger = require('../../utils/eventLogger');

module.exports = (req, res) => {
  logger.emit('success');
  res.status(201).send('POST success');
};
