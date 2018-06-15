from twilio.rest import TwilioRestClient
from twilio.rest.resources import Call
 
 
client = TwilioRestClient()
 
for call in client.calls.iter(status=Call.QUEUED):
    call.hangup()
 
for call in client.calls.iter(status=Call.RINGING):
    call.hangup()
 
for call in client.calls.iter(status=Call.IN_PROGRESS):
    call.hangup()
