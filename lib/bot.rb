require 'facebook/messenger'
require 'httparty'

# load environment vars, db, workers, and STScripts
# load STScripts
# load workers
require_relative '../config/environment'
require_relative 'workers'

# configure facebook-messenger gem 
include Facebook::Messenger
Facebook::Messenger.configure do |config|
  config.access_token = ENV['FB_ACCESS_TKN']
  config.app_secret   = ENV['APP_SECRET']
  config.verify_token = ENV['FB_VERIFY_TKN']
end

# custom fb helpers that we wrote
require_relative 'helpers/fb'
include Facebook::Messenger::Helpers


# demo sequence!
DEMO    = /demo/i
INTRO   = /intro/i
# reach us on QuialTime! :)
#
# aubrey 10209571935726081
# phil 10209486368143976
# david 1042751019139427

STORY_BASE_URL = 'https://s3.amazonaws.com/st-messenger/'

JOIN    = /join/i

scripts  = Birdv::DSL::ScriptClient.scripts


DAY_RQST  = /day\d+/i
HELP_RQST = /(help)|(who is this)|(who's this)|(who are you)/i
STOP_RQST = /(stop)|(unsubscribe)|(quit)|(mute)/i
THANK_MSG = /(thank you)|(thanks)|(thank)|(thx)|(thnks)|(thank u)/i
HAHA_MSG = /(ha)+/i 
ROBOT_MSG = /(robot)|(bot)|(automatic)|(automated)|(computer)|(human)|(person)/i



def get_reply(body, user)
  our_reply = ''

  case body
  when HELP_RQST
    our_reply =  "Hi, this is StoryTime! We help your teacher send free nightly stories.\n\n - To stop, reply ‘stop’\n - For help, contact 561-212-5831"
  when STOP_RQST
    user.state_table.update(subscribed?: false)
    our_reply =  "Okay, you'll stop getting messages! If you want free books again just enter 'go.'"
  when THANK_MSG
    our_reply = "You're welcome :)"
  when HAHA_MSG
    our_reply = ":D"
  when ROBOT_MSG
    our_reply = "Hi __PARENT__! StoryTime is an automated program that helps your teacher. If you need help just enter 'help.'"
  else #default msg 
    our_reply = "Hi __PARENT__! I'm away now, but I'll see your message soon. If you need help just enter 'help.'"
  end

  return our_reply 

end

def is_image?(message_attachments)
  not message_attachments.nil?
end

#
# i.e. when user sends the bot a message.
#
Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"
  sender_id = message.sender['id']

  attachments = message.attachments

  # enroll user if they don't exist in db
  db_user = User.where(:fb_id => sender_id).first 
  if db_user.nil?
      register_user(message.sender)
      BotWorker.perform_async(sender_id, 'day1', 'greeting')
  elsif is_image?(attachments) # user has been enrolled already + sent an image
      fb_send_txt(message.sender, ":)")
  else # user has been enrolled already...
      case message.text
      when DAY_RQST
        script_name = message.text.match(DAY_RQST).to_s
        if scripts[script_name] != nil
#          scripts[script_name].run_sequence(sender_id, :init)
          BotWorker.perform_async(sender_id, script_name, :init)
        else
          fb_send_txt(message.sender, "Sorry, that script is not yet available.")
        end
      else # find the appropriate reply
        reply = get_reply(message.text, db_user)
        fb_send_txt(message.sender, reply)
      end # case message.text
  end # db_user.nil?

   
end

#
# i.e. when user taps a button
#
Bot.on :postback do |postback|
  sender_id = postback.sender['id']
  case postback.payload
  when INTRO
    BotWorker.perform_async(sender_id, 'day1', 'greeting')
  else 
    # log the user's button press and execute sequence
    script_name, sequence = postback.payload.split('_')
    puts script_name
    puts sequence
    BotWorker.perform_async(sender_id, script_name, sequence)
  end
end


#
# i.e. a reciept from facebook
#
Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end




