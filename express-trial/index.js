
const express = require('express')
const app = express()
const path = require('path')

// First element is node. Second element is path of the javascript file.
// Third+ elements are arguments to the javascript script.
const port = process.argv.length > 2 ? process.argv[2] : 4500;

console.log(port);

app.use(express.static('__site__/static'))

app.get('/', function (req, res) {
   res.sendFile(path.resolve(__dirname, 'index.html'));
});

app.listen(port, function () {
  console.log(`app listening on port ${port}!`);
});
