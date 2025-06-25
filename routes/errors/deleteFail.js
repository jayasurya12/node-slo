module.exports = (req, res) => {
  res.status(500).send('DELETE failed: Simulated error');
};