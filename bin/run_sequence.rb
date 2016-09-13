require 'httparty'

localhost = "http://localhost:5000/run_sequence"
birdv     = "http://birdv.herokuapp.com/run_sequence"

puts HTTParty.get(
  birdv,
  query: {
    script: "day4",
    sequence: "storysequence",
    platform: "fb",
    recipient: "1113961265343345"
  }
)