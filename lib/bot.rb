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

def register_user(recipient)
  # save user in the database.
  # TODO : update an existing DB entry to coincide the fb_id with phone_number
  begin
    fields = "first_name,last_name,profile_pic,locale,timezone,gender"
    data = JSON.parse HTTParty.get("https://graph.facebook.com/v2.6/#{recipient['id']}?fields=#{fields}&access_token=#{ENV['FB_ACCESS_TKN']}").body
    name = data['first_name'] + " " + data["last_name"]
  rescue
    User.create(:fb_id => recipient["id"])
  else
    puts "successfully found user data for #{name}"
    last_name = data["last_name"]
    regex = /[a-zA-Z]*( )?#{last_name}/i  # if child's last name matches, go for it
    begin
      candidates = User.where(:child_name => regex, :fb_id => nil)
      if candidates.all.empty? # add a new user w/o child info (no matches)
        User.create(:fb_id => recipient['id'], :name => name, :gender => data['gender'], :locale => data['locale'], :profile_pic => data['profile_pic'])
      else
        # implement stupid fb_name matching to existing user matching
        candidates.order(:enrolled_on).first.update(:fb_id => recipient['id'], :name => name, :gender => data['gender'], :locale => data['locale'], :profile_pic => data['profile_pic'])
      end
    rescue Sequel::Error => e
      p e.message + " did not insert, already exists in db"
    end # rescue - db transaction
  end # rescue - httparty
end

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
  case message.text
  when DAY_RQST
    script_name = message.text.match(DAY_RQST).to_s
    if scripts[script_name] != nil
      scripts[script_name].run_sequence(sender_id, :init)
    else
      fb_send_txt(sender_id, "Sorry, that script is not yet available.")
    end
  when JOIN    
    register_user(message.sender) 
    fb_send_txt( message.sender, 
      "You're enrolled! Get ready for free stories!"
    )
  else 
    tuser = fb_get_user(message.sender)
    # come up with contingency if this happens
    # user = User.where(:fb_id => message.sender['id']).first
    # teacher = user.teacher.nil? ? "your teacher" : user.teacher.signature

    fb_send_txt( message.sender, 
      "StoryTime: Thanks, #{tuser['first_name']}! I’ll send your message to your teacher to see next time they are on their computer."
    )
  end
end

#
# i.e. when user taps a button
#
Bot.on :postback do |postback|
  sender_id = postback.sender['id']
  case postback.payload
  when INTRO
    register_user(postback.sender)
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




