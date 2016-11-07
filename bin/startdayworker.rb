require 'httparty'


# 10209967651611613
localhost = "http://localhost:5000/"
birdv     = "http://birdv.herokuapp.com/"

puts HTTParty.get(
  localhost + "startdayworker",
  query: {
    platform: "fb"
  }
)