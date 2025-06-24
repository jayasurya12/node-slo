module.exports = async (req, res) => {
  await Promise.reject(new Error('Async function failed'));
};
