require 'facebook/messenger'
require 'httparty'

# load environment vars, db, workers, and STScripts
# load STScripts
# load workers
require_relative '../config/environment'
require_relative '../config/initializers/redis'

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

STORY_BASE_URL = 'http://d2p8iyobf0557z.cloudfront.net/'

JOIN    = /join/i

scripts  = Birdv::DSL::ScriptClient.scripts

# TODO: add Spanish words here
DAY_RQST  = /day\d+/i
HELP_RQST = /(help)|(who is this)|(who's this)|(who are you)|(ayuda)|(quien es este)|(quién eres tú)/i
STOP_RQST = /(stop)|(unsubscribe)|(quit)|(mute)|(parada)|(dejar)/i
THANK_MSG = /(thank you)|(thanks)|(thank)|(thx)|(thnks)|(thank u)|(gracias)/i
HAHA_MSG = /(ha)+|(ja)+/i 
ROBOT_MSG = /(robot)|(bot)|(automatic)|(automated)|(computer)|(human)|(person)|(humano)/i



def get_reply(body, user)
  our_reply = ''
  I18n.locale = user.locale

  case body
  when HELP_RQST
    our_reply =  I18n.t 'user_response.help'
  when STOP_RQST
    user.state_table.update(subscribed?: false)
    our_reply =  I18n.t 'user_response.stop'
  when THANK_MSG
    our_reply = I18n.t 'user_response.thanks'
  when HAHA_MSG
    our_reply = ":D"
  when ROBOT_MSG
    our_reply = I18n.t 'user_response.robot'
  else #default msg 
    our_reply = I18n.t 'user_response.default'
  end
  return our_reply 

end

def is_image?(message_attachments)
  not message_attachments.nil?
end

# Was the previous message unknown?
def prev_unknown?(user)
  # Look up if bot's last reply was to UNKOWN message
  redis_msg_key = user.fb_id + "_last_message_text"
  users_last_msg = REDIS.get(redis_msg_key)
  bot_last_reply = get_reply(users_last_msg, user)
  prev_was_unknown  = (bot_last_reply == (I18n.t 'user_response.default')) 

  # Ensure that there also WAS a last message
  prev_was_unknown  = prev_was_unknown && !users_last_msg.nil?
  return prev_was_unknown
end


#
# i.e. when user sends the bot a message.
#
Bot.on :message do |message|
  #any image attachment
  attachments = message.attachments
  
  if !is_image?(attachments)
    puts "Received #{message.text} from #{message.sender}"
    the_new_msg = message.text
  end

  sender_id = message.sender['id']    

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

        if (reply == (I18n.t 'user_response.default')) && prev_unknown?(user)
          reply = "DON'T ASK ME TWICE"
        end
        fb_send_txt(message.sender, reply)
      end # case message.text
  end # db_user.nil?

  #update the last message
  redis_msg_key = db_user.fb_id + "_last_message_text"
  REDIS.set(redis_msg_key, the_new_msg)
   
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




