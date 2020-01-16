require('dotenv').load();

const http = require('http');
const path = require('path');
const express = require('express');
const bodyParser = require('body-parser')
const methods = require('./src/server.js');
const tokenGenerator = methods.tokenGenerator;
const makeCall = methods.makeCall;
const callAgent = methods.callAgent;
const roomAgent = methods.roomAgent;
const registerNumber = methods.registerNumber;
const checkNumber = methods.checkNumber;
var twilio = require('twilio');

// Create Express webapp
const app = express();

// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }))

app.use(express.static(__dirname + '/public'));

app.get('/accessToken', function(request, response) {
  tokenGenerator(request, response);
});

app.post('/accessToken', function(request, response) {
  tokenGenerator(request, response);
});

app.get('/makeCall', function(request, response) {
  makeCall(request, response);
});

app.post('/makeCall', function(request, response) {
  makeCall(request, response);
});

app.get('/roomAgent/:from', function(request, response) {
  roomAgent(request, response);
});

app.post('/roomAgent/:from', function(request, response) {
  roomAgent(request, response);
});

app.get('/registerNumber', function(request, response) {
  registerNumber(request, response);
});

app.get('/checkNumber', function(request, response) {
  checkNumber(request, response);
});



app.get('/callAgent', callAgent);

app.post('/callAgent', callAgent);


// Create an http server and run it
const server = http.createServer(app);
const port = process.env.PORT || 3000;
server.listen(port, function() {
  console.log('Express server running on *:' + port);
});
