module.exports = {
  handled: require('./handledError'),
  unhandled: require('./unhandledError'),
  async: require('./asyncError'),
  customSpan: require('./customSpanError'),
  json: require('./jsonError'),
  deleteFail: require('./deleteFail'),
  updateFail: require('./updateFail')
};
