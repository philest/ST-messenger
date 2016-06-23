# curl -X GET "https://graph.facebook.com/v2.6/$david?fields=first_name,last_name,profile_pic,locale,timezone,gender&access_token=$token"

# curl -X GET "https://graph.facebook.com/v2.6/$david?fields=first_name,last_name&access_token=$token"
# phil 15612125831

curl -X POST -H "Content-Type: application/json" -d '{
  "recipient":{
    "phone_number": ""
  },
  "message":{
    "text": "hello world"
  }
}' "https://graph.facebook.com/me/messages?access_token="


# curl -X POST -H "Content-Type: application/json" -d '{
#   "recipient":{
#     "id":10209967651611613
#   },
#   "message":{
#     "attachment":{
#       "type":"image",
#       "payload":{
#         "url":"https://s3.amazonaws.com/st-messenger/old_stories/bb/bb1.jpg"
#       }
#     }
#   }
# }' -i "https://graph.facebook.com/v2.6/me/messages?access_token=$access_token"