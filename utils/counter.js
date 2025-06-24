let incomingCount = 0;
let outgoingCount = 0;

module.exports = {
  increaseIncoming: () => ++incomingCount,
  increaseOutgoing: () => ++outgoingCount,
  getCounts: () => ({ incomingCount, outgoingCount }),
};
