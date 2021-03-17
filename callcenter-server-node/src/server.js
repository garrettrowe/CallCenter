require('dotenv').load();
const moment = require('moment');
const AccessToken = require('twilio').jwt.AccessToken;
const VoiceGrant = AccessToken.VoiceGrant;
const VoiceResponse = require('twilio').twiml.VoiceResponse;
const defaultIdentity = 'alice';
var agentNumber = '18587794426';
var agentmapping = {};


/**
 * Creates an access token with VoiceGrant using your Twilio credentials.
 *
 * @param {Object} request - POST or GET request that provides the recipient of the call, a phone number or a client
 * @param {Object} response - The Response Object for the http request
 * @returns {string} - The Access Token string
 */
function tokenGenerator(request, response) {
  // Parse the identity from the http request
  var identity = null;
  if (request.method == 'POST') {
    identity = request.body.identity;
    agentmapping["a" + identity] = request.body.agent;
  } else {
    identity = request.query.identity;
    agentmapping["a" + identity] = request.query.agent;
  }

  if(!identity) {
    identity = defaultIdentity;
  }

  // Used when generating any kind of tokens
  const accountSid = process.env.ACCOUNT_SID;
  const apiKey = process.env.API_KEY;
  const apiSecret = process.env.API_KEY_SECRET;

  // Used specifically for creating Voice tokens
  const pushCredSid = process.env.PUSH_CREDENTIAL_SID;
  const outgoingApplicationSid = process.env.APP_SID;

  // Create an access token which we will sign and return to the client,
  // containing the grant we just created
  const voiceGrant = new VoiceGrant({
      outgoingApplicationSid: outgoingApplicationSid,
      pushCredentialSid: pushCredSid
    });

  // Create an access token which we will sign and return to the client,
  // containing the grant we just created
  const token = new AccessToken(accountSid, apiKey, apiSecret);
  token.addGrant(voiceGrant);
  token.identity = identity;
  console.log('Mapped phone:' + identity + " to agent " + agentmapping["a" + identity]);
  console.log('Token:' + token.toJwt());
  return response.send(token.toJwt());
}

async function checkNumber(request, response){
  var number = request.query.number;
  var n = 0;
  client= getClient();

  id = await client.outgoingCallerIds.list();

  for (var i = 0; i < id.length; i++) {
    if(id[i].phoneNumber == ("+" + number)){
      n = 1;
    }
  }
  return response.send(JSON.stringify(n));
}

async function registerNumber(request, response){
  client= getClient();
  var number = request.query.number;

  validation_request = await client.api.validationRequests.create({
         phoneNumber: number,
         callDelay: 10
       });
  return response.send(JSON.stringify(validation_request.validationCode));
}

function killCalls(request, response) {
  client= getClient();
  client.calls.each({
     status: 'in-progress'
   },
       calls => {
        var then = moment(calls.startTime, "YYYY-MM-DD'T'HH:mm:ss:SSSZ");
        var now = moment();
        var diff = moment.duration(then.diff(now));
        if (diff < 0) {
            diff = Math.abs(diff);
        }
        var d = moment.utc(diff).format("m");
        console.log("Call " + calls.sid + " in progress for: " + d);
        if (d > 9){
          client.calls(calls.sid).update({status: 'completed'})
          console.log("Ended call " + calls.sid);
        }
      }
   );
}

setInterval(killCalls, 60000);

function roomAgent(request, response) {
  var to = null;
  var from = request.params.from;
  voiceResponse = '<?xml version="1.0" encoding="UTF-8"?><Response><Dial><Conference>' + from + '</Conference></Dial></Response>';
  return response.send(voiceResponse);
}

function getClient(){
  const accountSid = process.env.ACCOUNT_SID;
  const apiKey = process.env.API_KEY;
  const apiSecret = process.env.API_KEY_SECRET;
  const client = require('twilio')(apiKey, apiSecret, { accountSid: accountSid } );

  return client;
}

async function callF(to, from, agent, callback) {
  var url = "https://conciergevoiceserver.mybluemix.net/roomAgent/" + from;
  client= getClient();
  console.log("Calling number:" + to);
  if (callback){
    call = await client.api.calls.create({
      url: url,
      to: to,
      from: from,
      statusCallback: 'https://localhost/agentCallback?from='+from,
      statusCallbackEvent: ["answered", "completed"],
      statusCallbackMethod: 'POST'
    });
  }else{
    call = await client.api.calls.create({
      url: url,
      to: to,
      from: from
    });
  }
  return call.sid;
}

async function callAgent(request, response) {
  var from = null;
  if (request.method == 'POST') {
    from = request.body.from;
  } else {
    from = request.query.from;
  }
  agent = agentmapping["a" + from];
  return response.send(callF(agent, from, agent, true));
}

function makeCall(request, response) {
  var to = null;
  var numbers = null;
  var from = null;
  var agent = null;
  if (request.method == 'POST') {
    to = request.body.to;
    numbers = request.body.from.split("+");
  } else {
    to = request.query.to;
    numbers = request.query.from.split("+");
  }
  agent = numbers[0];
  from = numbers[1]

  console.log('Making call to  ' + to + " and placing in conference " + from);
  
  const voiceResponse = new VoiceResponse();
  const dial = voiceResponse.dial({ringTone : "none"});
  dial.conference(from,{endConferenceOnExit: true,startConferenceOnEnter: true, beep: false, waitMethod: 'GET', waitUrl: 'https://conciergevoiceserver.mybluemix.net/wav.wav', statusCallback: 'https://customerconcierge.mybluemix.net/speakerCallback?from='+from, statusCallbackEvent: "speaker"});
  callF(to, from, agent, false);
  
  console.log('Response:' + voiceResponse.toString());
  return response.send(voiceResponse.toString());
}

exports.tokenGenerator = tokenGenerator;
exports.makeCall = makeCall;
exports.callAgent = callAgent;
exports.roomAgent = roomAgent;
exports.registerNumber = registerNumber;
exports.checkNumber = checkNumber;
