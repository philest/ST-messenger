
# curl -X POST -H "Content-Type: application/json" -d '{
#   "setting_type":"greeting",
#   "greeting":{
#     "text":"Hi! We have free books from your child’s teacher! Just tap \"Get Started\"." 
#   }
# }' "https://graph.facebook.com/v2.6/me/thread_settings?access_token="    


# curl -X DELETE -H "Content-Type: application/json" -d '{
#   "setting_type":"call_to_actions",
#   "thread_state":"new_thread"
# }' "https://graph.facebook.com/v2.6/me/thread_settings?access_token="    

# string="Let's read your first story!"

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
#                 "title":"Welcome to StoryTime! Here is your first story.",
#                 "image_url":"https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg",
#                 "buttons":[
#                   {
#                     "type":"postback",
#                     "title":"Tap here!",
#                     "payload":"day1_coonstory"
#                   }
#                 ]
#               }
#             ]
#           }
#         }
#       }
#     }
#   ]
# }' "https://graph.facebook.com/v2.6//thread_settings?access_token="

# curl -X POST -H "Content-Type: application/json" -d '{
#   "setting_type":"call_to_actions",
#   "thread_state":"new_thread",
#   "call_to_actions":[]
# }' "https://graph.facebook.com/v2.6//thread_settings?access_token="
