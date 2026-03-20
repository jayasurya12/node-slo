module.exports = {
  handled: require('./handledError'),
  unhandled: require('./unhandledError'),
  async: require('./asyncError'),
  customSpan: require('./customSpanError'),
  deleteFail: require('./deleteFail'),
  updateFail: require('./updateFail')
};