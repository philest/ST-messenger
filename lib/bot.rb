require 'facebook/messenger'
require 'activerecord-jdbcpostgresql-adapter' if RUBY_PLATFORM == 'java'
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
# david 10209967651611613

STORY_BASE_URL = 'https://s3.amazonaws.com/st-messenger/'

JOIN    = /join/i

scripts  = Birdv::DSL::StoryTimeScript.scripts


DAY_RQST = /day\d+/i

#
# i.e. when user sends the bot a message.
#
Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"
  sender_id = message.sender['id']

  # enroll user if they don't exist in db
  db_user = User.where(:fb_id => sender_id).first 
  if db_user.nil?
    register_user(message.sender)
  end # enroll

  case message.text
  when DAY_RQST
    script_name = message.text.match(DAY_RQST).to_s
    if scripts[script_name] != nil
      scripts[script_name].run_sequence(sender_id, :init)
    else
      fb_send_txt(sender_id, "Sorry, that script is not yet available.")
    end

  else # any other text....
    tuser = fb_get_user(message.sender)
    db_user = User.where(:fb_id => sender_id).first
    teacher = db_user.teacher.nil? ? "your teacher" : db_user.teacher.signature
    msg = "Thanks, #{tuser['first_name']}! I’ll send your message to #{teacher} to see next time they are on their computer." 

    fb_send_txt( message.sender, msg )
  end
end

#
# i.e. when user taps a button
#
Bot.on :postback do |postback|
  sender_id = postback.sender['id']
  case postback.payload
  when INTRO
    BotWorker.perform_async(sender_id, 'day1', :init)
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




