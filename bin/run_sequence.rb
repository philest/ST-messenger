require 'httparty'


# 10209967651611613
localhost = "http://localhost:5000/"
birdv     = "http://birdv.herokuapp.com/"

puts HTTParty.get(
  localhost + "run_sequence",
  query: {
    script: "day4",
    sequence: "storysequence",
    platform: "fb",
    # recipient: '1264968273534707'
  }
)

# puts HTTParty.get(
#   birdv + "startdayworker",
#   query: {
#     platform: 'fb',
#     recipient: '821157484652852'
#   }
# )
 
