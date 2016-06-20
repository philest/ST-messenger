curl -X POST -H "Content-Type: application/json" -d '{
  "setting_type":"call_to_actions",
  "thread_state":"new_thread",
  "call_to_actions":[
    {
      "message":{
        "attachment":{
          "type":"template",
          "payload":{
            "template_type":"generic",
            "elements":[
              {
                "title":"Welcome to StoryTime!",
                "item_url":"http://www.joinstorytime.com/",
                "image_url":"http://media.dunkedcdn.com/assets/prod/73484/950x0_p18e1d3irvk7g18p4hks3frrm03.jpg",
                "subtitle":"Sending nightly bedtime stories for you and your kids.",
                "buttons":[
                  {
                    "type":"postback",
                    "title":"Get stories",
                    "payload":"INTRO"
                  }
                ]
              }
            ]
          }
        }
      }
    }
  ]
}' "https://graph.facebook.com/v2.6/$page_id/thread_settings?access_token=$access_token"
