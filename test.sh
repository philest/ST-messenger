curl -X POST -H "Content-Type: application/json" -d '{
  "recipient":{
    "id":"1042751019139427"
  },
  "message":{
    "attachment":{
      "type":"template",
      "payload":{
        "template_type":"button",
        "text":"What do you want to do next?",
        "buttons":[
          {
            "type":"web_url",
            "url":"https://petersapparel.parseapp.com",
            "title":"Show Website"
          },
        ]
      }
    }
  }
}' "https://graph.facebook.com/v2.6/me/messages?access_token="