require 'httparty'

localhost = "http://localhost:5000/run_sequence"
birdv     = "http://birdv.herokuapp.com/run_sequence"

puts HTTParty.get(
  localhost,
  query: {
    script: "day1",
    sequence: "storybutton",
    platform: "fb",
    recipient: '10209967651611613'
  }
)
 
