require 'httparty'

puts HTTParty.get(
  "http://localhost:5000/run_sequence",
  query: {
    script: "day4",
    sequence: "firstmessage",
    platform: "sms",
    recipient: "8186897323"
  }
)