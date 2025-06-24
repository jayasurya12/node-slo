const logger = require('../../utils/eventLogger');

module.exports = (req, res) => {
  logger.emit('error');
  throw new Error('This is an unhandled server error!');
};
