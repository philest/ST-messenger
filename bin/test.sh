# curl -X GET "https://graph.facebook.com/v2.6/$david?fields=first_name,last_name,profile_pic,locale,timezone,gender&access_token=$token"

# curl -X GET "https://graph.facebook.com/v2.6/$david?fields=first_name,last_name&access_token=$token"


# curl -X POST -H "Content-Type: application/json" -d '{
#     "recipient":{
#         "id":10209967651611613
#     }, 
#     "message":{
#         "text":"hello, world!"
#     }
# }' "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAD41w1cxfQFTuzzjbpFQ4da1GdtRjmDYhFGTCd3KOIiE5UQIbEUQwVOsFN0Tz7WsyDIFdQf2Nm0j0sA99qZAV5RZCjcFz89S4kZBZCLZA3foj33svFrmJ7yZCZCe3e16xk9jZBZAXa88jRt1yD348EnqYZCZAvHFVTPiwZDZD"

# 10209967651611613

curl -X POST -H "Content-Type: application/json" -d '{
  "recipient":{
    "id":
  },
  "message":{
    "attachment":{
      "type":"image",
      "payload":{
        "url":"https://s3.amazonaws.com/st-messenger/old_stories/bb/bb1.jpg"
      }
    }
  }
}' -i "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAD41w1cxfQFTuzzjbpFQ4da1GdtRjmDYhFGTCd3KOIiE5UQIbEUQwVOsFN0Tz7WsyDIFdQf2Nm0j0sA99qZAV5RZCjcFz89S4kZBZCLZA3foj33svFrmJ7yZCZCe3e16xk9jZBZAXa88jRt1yD348EnqYZCZAvHFVTPiwZDZD"

# curl -X POST -H "Content-Type: application/json" -d '{
#   "object":"page",
#   "entry":[
#     {
#       "id":1625783961083197,
#       "time":1457764198246,
#       "messaging":[
#         {
#           "sender":{
#             "id":"10209967651611602"
#           },
#           "recipient":{
#             "id":"1625783961083187"
#           },
#           "timestamp":1457764197627,
#           "message":{
#             "mid":"mid.1457764197618:41d102a3e1ae206a38",
#             "seq":73,
#             "text":"hello, world!"
#           }
#         }
#       ]
#     }
#   ]
# }' "https://quailtime.localtunnel.me/bot"
