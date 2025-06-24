const logger = require('../../utils/eventLogger');

module.exports = (req, res) => {
  logger.emit('success');
  res.status(200).send('OK 200 - Success');
};
