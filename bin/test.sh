# curl -X GET "https://graph.facebook.com/v2.6/$david?fields=first_name,last_name,profile_pic,locale,timezone,gender&access_token=$token"

# curl -X GET "https://graph.facebook.com/v2.6/$david?fields=first_name,last_name&access_token=$token"



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
}' -i "https://graph.facebook.com/v2.6/me/messages?access_token=$access_token"


