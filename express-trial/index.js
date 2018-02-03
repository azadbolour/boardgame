
const express = require('express')
const app = express()
const path = require('path')

const port = 4500;

app.use(express.static('__site__/static'))

app.get('/', function (req, res) {
   res.sendFile(path.resolve(__dirname, 'index.html'));
});

app.listen(port, function () {
  console.log(`app listening on port ${port}!`);
});
