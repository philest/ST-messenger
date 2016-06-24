require 'facebook/messenger'
require 'activerecord-jdbcpostgresql-adapter' if RUBY_PLATFORM == 'java'
require 'sequel'
require 'httparty'
require 'sidekiq'

# load environment vars
require_relative '../../config/environment'

# load STScripts
require_relative 'dsl'
Dir.glob("#{File.expand_path("", File.dirname(__FILE__))}/../sequence_scripts/*")
      .each {|f| require_relative f }

# load workers
require_relative 'worker_bot'

# configure facebook-messenger gem 
include Facebook::Messenger
Facebook::Messenger.configure do |config|
  config.access_token = ENV['FB_ACCESS_TKN']
  config.app_secret   = ENV['APP_SECRET']
  config.verify_token = ENV['FB_VERIFY_TKN']
end

# custom fb helpers that we wrote
require_relative 'fb_helpers'
include Facebook::Messenger::Helpers

# demo sequence!
require_relative 'demo'
DEMO    = /demo/i
INTRO = /intro/i

# reach us on QuialTime! :)
#
# aubrey 10209571935726081
# phil 10209486368143976
# david 10209967651611613

def register_user(recipient)
  # save user in the database.
  # TODO : update an existing DB entry to coincide the fb_id with phone_number
  begin
    users = DB[:users] 
    begin
      fb_name = HTTParty.get("https://graph.facebook.com/v2.6/#{recipient['id']}?fields=first_name,last_name&access_token=#{ENV['FB_ACCESS_TKN']}")
      name = fb_name["first_name"] + " " + fb_name["last_name"]
    rescue HTTParty::Error
      name = nil
    else
      puts "successfully found name"
    end

    begin 
      users.insert(:name => name, :fb_id => recipient["id"])
      puts "inserted #{name}:#{recipient} into the users table"
    rescue Sequel::UniqueConstraintViolation => e
      p e.message << " ::> did not insert, already exists in db"
    rescue Sequel::Error => e
      p e.message << " ::> failure"
    end
  rescue Sequel::Error => e
    p e.message
  end
end

STORY_BASE_URL = 'https://s3.amazonaws.com/st-messenger/'

JOIN    = /join/i
DAY1    = /day1/i
DAY2    = /day2/i
DAY3    = /day3/i

scripts = Birdv::DSL:StoryTimeScript.scripts

#
# i.e. when user sends the bot a message.
#
Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"

  case message.text
  when DAY1
    scripts['day1'].run_sequence(message.sender,  'init')
  when DAY2
    scripts['day2'].run_sequence(message.sender,  'init')
  when DAY3
    scripts['day3'].run_sequence(message.sender,  'init')
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
  # TODO: log the postback into DB
  case postback.payload
  when INTRO
    register_user(postback.sender)
  else 
    script_name, sequence = postback.payload.split('_')
    scripts[script_name].run_sequence(postback.sender, sequence)
  end
end


#
# i.e. a reciept from facebook
#
Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end




