const EventEmitter = require('events');
class RequestLogger extends EventEmitter {}

const logger = new RequestLogger();

let successCount = 0;
let errorCount = 0;

logger.on('success', () => {
  successCount++;
  console.log(`✅ Success Count: ${successCount}`);
});

logger.on('error', () => {
  errorCount++;
  console.log(`❌ Error Count: ${errorCount}`);
});

module.exports = logger;
