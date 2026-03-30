const logger = require('../../utils/eventLogger');

// Supported HTTP error status codes
const SUPPORTED_CODES = [
    400, 401, 402, 403, 404, 405, 406, 407, 408, 409,
    410, 411, 412, 413, 414, 415, 416, 417, 418, 422,
    423, 424, 425, 426, 428, 429, 431, 451,
    500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511
];

const STATUS_MESSAGES = {
    400: 'Bad Request',
    401: 'Unauthorized',
    402: 'Payment Required',
    403: 'Forbidden',
    404: 'Not Found',
    405: 'Method Not Allowed',
    406: 'Not Acceptable',
    407: 'Proxy Authentication Required',
    408: 'Request Timeout',
    409: 'Conflict',
    410: 'Gone',
    411: 'Length Required',
    412: 'Precondition Failed',
    413: 'Payload Too Large',
    414: 'URI Too Long',
    415: 'Unsupported Media Type',
    416: 'Range Not Satisfiable',
    417: 'Expectation Failed',
    418: "I'm a Teapot",
    422: 'Unprocessable Entity',
    423: 'Locked',
    424: 'Failed Dependency',
    425: 'Too Early',
    426: 'Upgrade Required',
    428: 'Precondition Required',
    429: 'Too Many Requests',
    431: 'Request Header Fields Too Large',
    451: 'Unavailable For Legal Reasons',
    500: 'Internal Server Error',
    501: 'Not Implemented',
    502: 'Bad Gateway',
    503: 'Service Unavailable',
    504: 'Gateway Timeout',
    505: 'HTTP Version Not Supported',
    506: 'Variant Also Negotiates',
    507: 'Insufficient Storage',
    508: 'Loop Detected',
    510: 'Not Extended',
    511: 'Network Authentication Required',
};

/**
 * GET /error/status/:code
 * Returns the given HTTP error status code.
 * Supported codes: 4xx and 5xx
 */
module.exports = (req, res) => {
    const code = parseInt(req.params.code, 10);

    if (!SUPPORTED_CODES.includes(code)) {
        return res.status(400).json({
            error: 'Unsupported status code',
            supported: SUPPORTED_CODES,
        });
    }

    logger.emit('error');
    const message = STATUS_MESSAGES[code] || 'Error';
    return res.status(code).json({
        statusCode: code,
        error: message,
        timestamp: new Date().toISOString(),
    });
};

module.exports.SUPPORTED_CODES = SUPPORTED_CODES;
module.exports.STATUS_MESSAGES = STATUS_MESSAGES;
