require 'httparty'


# 10209967651611613
localhost = "http://localhost:5000/"
birdv     = "http://birdv.herokuapp.com/"

# fb_ids = %w(410582582399330 1272545332810367 1118791721561706 1160954020618887 1712062875486643)



  puts HTTParty.get(
    localhost + "startdayworker",
    query: {
      platform: "fb",
      recipient: '1229083957198990'
    }
  )


# expect story 