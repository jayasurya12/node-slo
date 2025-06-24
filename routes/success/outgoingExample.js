const axios = require('axios');
const { increaseOutgoing } = require('../../utils/counter');

module.exports = async (req, res) => {
  const current = increaseOutgoing();
  console.log(`📈 Total Outgoing Requests: ${current}`);

  try {
    const response = await axios.get('https://jsonplaceholder.typicode.com/todos/1');
    res.status(200).send(response.data);
  } catch (err) {
    res.status(500).send('Failed external call');
  }
};
