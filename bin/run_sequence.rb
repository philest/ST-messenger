require 'httparty'


# 10209967651611613
localhost = "http://localhost:5000/run_sequence"
birdv     = "http://birdv.herokuapp.com/run_sequence"

puts HTTParty.get(
  localhost,
  query: {
    script: "day1",
    sequence: "firstmessage",
    platform: "sms",
    recipient: '8186897323'
  }
)
 
