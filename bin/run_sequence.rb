require 'httparty'


# 10209967651611613
localhost = "http://localhost:5000/"
birdv     = "http://birdv.herokuapp.com/"

puts HTTParty.get(
  localhost + "run_sequence",
  query: {
    script: "day4",
    sequence: "goodbye",
    platform: "sms",
    # recipient: '3013328953'
  }
)

# puts HTTParty.get(
#   birdv + "startdayworker",
#   query: {
#     platform: 'fb',
#     recipient: '821157484652852'
#   }
# )
 
