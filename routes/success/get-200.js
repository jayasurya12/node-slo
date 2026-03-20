const logger = require('../../utils/eventLogger');

module.exports = (req, res) => {
    logger.emit('success');
    res.status(200).json({
        status: 200,
        message: 'OK - GET request successful',
        timestamp: new Date().toISOString(),
        path: req.path
    });
};
