const logger = require('../../utils/eventLogger');


exports.post = (req, res) => {
    logger.emit('success');
    res.status(201).send('POST success');
};
