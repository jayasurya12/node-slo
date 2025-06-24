module.exports = (req, res) => {
  console.log('⚠️ Handling error intentionally...');
  res.status(500).send('Handled error: Something went wrong!');
};
