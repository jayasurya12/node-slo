// routes/slow/timeout.js
module.exports = (req, res) => {
  console.log('⏳ Slow route triggered. Waiting 2 minutes...');
  setTimeout(() => {
    res.status(200).send('Response after 2 minutes delay!');
  }, 120000); // 2 minutes = 120,000 ms
};
