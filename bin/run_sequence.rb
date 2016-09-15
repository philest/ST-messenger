require 'httparty'


# 10209967651611613
localhost = "http://localhost:5000/run_sequence"
birdv     = "http://birdv.herokuapp.com/run_sequence"

puts HTTParty.get(
  birdv,
  query: {
    script: "day2",
    sequence: "storybutton",
    platform: "fb",
    recipient: '1042751019139427'
  }
)
 
