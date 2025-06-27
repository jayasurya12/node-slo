const logger = require('../../utils/eventLogger');

exports.put = (req, res) => {
    logger.emit('success');
    res.status(200).send('PUT success');
};
