require 'facebook/messenger'
require 'activerecord-jdbcpostgresql-adapter' if RUBY_PLATFORM == 'java'
require 'sequel'
require 'httparty'
require 'sidekiq'

# load environment vars
require_relative '../config/environment' # we can do this cos I added 
                             # root to path (see config.ru)

# load STScripts
require_relative 'bot/dsl'
Dir.glob("#{File.expand_path("", File.dirname(__FILE__))}/sequence_scripts/*")
      .each {|f| require_relative f }

# load workers
require_relative 'workers/worker_bot'

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


#
# i.e. when user sends the bot a message.
#
Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"
  sender_id = message.sender['id']
  case message.text
  when DEMO
  	#intro(message.sender)
    scripts['day1'].run_sequence(sender_id, :init)
  when JOIN    
    register_user(message.sender) 
    fb_send_txt( message.sender, 
      "You're enrolled! Get ready for free stories!"
    )
  else 
    tuser = fb_get_user(message.sender)
    fb_send_txt( message.sender, 
      "Thanks, #{tuser['first_name']}! I’ll send your message to Ms. Stobierski to see next time she’s on her computer."
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
    StoryTimeScriptWorker.perform_async(sender_id, 'day1', :init)
  else 
    # log the user's button press and execute sequence
    script_name, sequence, day_incr = postback.payload.split('_')
    puts script_name
    puts sequence
    StoryTimeScriptWorker.perform_async(sender_id, script_name, sequence, day_incr)
  end
end


#
# i.e. a reciept from facebook
#
Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end




