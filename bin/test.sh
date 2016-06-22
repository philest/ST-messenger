# curl -X GET "https://graph.facebook.com/v2.6/$david?fields=first_name,last_name,profile_pic,locale,timezone,gender&access_token=$token"

# curl -X GET "https://graph.facebook.com/v2.6/$david?fields=first_name,last_name&access_token=$token"
# phil 15612125831

curl -X POST -H "Content-Type: application/json" -d '{
  "recipient":{
    "id": "10209967651611613"
  },
  "message":{
    "attachment":{
      "type":"template",
      "payload":{
        "template_type":"button",
        "text":"Hello you rascal!",
        "buttons":[
          {
            "type":"web_url",
            "url":"https://petersapparel.parseapp.com",
            "title":"Show Website"
          },
          {
            "type":"postback",
            "title":"Join the cult",
            "payload":"8186897323"
          }
        ]
      }
    }
  }
}' "https://graph.facebook.com/me/messages?access_token=${FB_ACCESS_TKN}"


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