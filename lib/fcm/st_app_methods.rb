require 'fcm'

module STApp
  @@Fcm = FCM.new(ENV["FCM_API_KEY_STAPP"])

  # TODO: hook this up to i18n?
  def STApp.demo_send_new_story ()
    puts ENV["FCM_API_KEY_STAPP"]

    puts "SHOULD AHVE SEEN STUFF"
    msg_title = "A new story has landed!"
    msg_body  = "Tap here to read it. :)"

    @@Fcm.send_to_topic( 'demo',
      notification: {
        title: msg_title,
        body: msg_body
      },
      data: {
        title: msg_title,
        body: msg_body,
        story_time_action: 'NEW_BOOK',
        timeSent: Time.now().to_i*1000 # this is important for the NEW_BOOK action
      },
      content_availible: true
    )
  end

  def STApp.poop
    puts '@@@@@@@@@@@@pee'
  end

end
