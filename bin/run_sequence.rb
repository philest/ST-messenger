require 'httparty'


# 10209967651611613
localhost = "http://localhost:5000/"
birdv     = "http://birdv.herokuapp.com/"

puts HTTParty.get(
  birdv + "run_sequence",
  query: {
    script: "day1",
    sequence: "firstmessage",
    platform: "sms",
    # recipient: '8608976597'
  }
)

# puts HTTParty.get(
#   birdv + "startdayworker",
#   query: {
#     platform: 'fb',
#     recipient: '821157484652852'
#   }
# )
 
