const logger = require('../../utils/eventLogger');

module.exports = (req, res) => {
  logger.emit('error');
  res.status(500).send('This is a handled error');
};
