require 'httparty'
require 'dotenv'
Dotenv.load

puts HTTParty.post(
  "https://graph.facebook.com/v2.6/#{ENV['FB_PAGE_ID']}/thread_settings?access_token=#{ENV['PRODUCTION_FB_ACCESS_TKN']}",
  body: {
    setting_type: "call_to_actions",
    thread_state: "new_thread",
    call_to_actions: [
      {
            payload: "intro"
      }

    ]
  },
  :headers => { 'Content-Type' => 'application/json' }
)
# payload: { template_type: "generic", elements: [ { title: "Let's read your first story.", image_url: "http://d2p8iyobf0557z.cloudfront.net/day1/tap_here.jpg", buttons: [ { type: "postback", title: "Tap here!", payload: "day1_coonstory"}]}]}

# curl -X POST -H "Content-Type: application/json" -d '{
#   "setting_type":"call_to_actions",
#   "thread_state":"new_thread",
#   "call_to_actions":[
#     {
#       "message":{
#         "attachment":{
#           "type":"template",
#           "payload":{
#             "template_type":"generic",
#             "elements":[
#               {
#                 "title":"Welcome to StoryTime! Let",
#                 "item_url":"http://www.joinstorytime.com/",
#                 "image_url":"http://d2p8iyobf0557z.cloudfront.net/day1/tap_here.jpg",
#                 "buttons":[
#                   {
#                     "type":"postback",
#                     "title":"Tap here!",
#                     "payload":"INTRO"
#                   }
#                 ]
#               }
#             ]
#           }
#         }
#       }
#     }
#   ]
# }' "https://graph.facebook.com/v2.6/490917624435792/thread_settings?access_token=EAAYOZCTY8IiwBAIZCkoKlZAHtpFcxBqHUKFUsNZCDUIcxVDWJqhiqdB4q0jDpaiubiYmRtZBBFjCMWE6jnoBoT6qAc2Tr1VtOl4L6RvJFKVFUScqavZByWsBROo1FGVSpcpsjKyFc4HtkjocuVAgcM3ITJPGxBNOndaRA7HFrhqQZDZD"