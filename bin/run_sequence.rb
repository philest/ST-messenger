require 'httparty'


# 10209967651611613
localhost = "http://localhost:5000/"
birdv     = "http://birdv.herokuapp.com/"

puts HTTParty.get(
  birdv + "run_sequence",
  query: {
    script: "day3",
    sequence: "greeting",
    platform: "fb",
    recipient: '1182882578424531'
  }
)

# puts HTTParty.get(
#   birdv + "startdayworker",
#   query: {
#     platform: 'fb',
#     recipient: '821157484652852'
#   }
# )
 
