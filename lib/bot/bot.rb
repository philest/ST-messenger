require 'facebook/messenger'
require 'activerecord-jdbcpostgresql-adapter' if RUBY_PLATFORM == 'java'
require 'sequel'
require 'httparty'

require_relative '../../config/environment'

Facebook::Messenger.configure do |config|
  config.access_token = ENV['FB_ACCESS_TKN']
  config.app_secret   = ENV['APP_SECRET']
  config.verify_token = ENV['FB_VERIFY_TKN']
end

# Facebook::Messenger::Subscriptions.subscribe
include Facebook::Messenger
require_relative 'demo'
require_relative 'intro'
require_relative 'day1'

# aubrey 10209571935726081
# phil 10209486368143976
# david 10209967651611602
# 
# david? 10209967651611613

def fb_send_txt(recipient, message)
  Bot.deliver(
    recipient: recipient, 
    message: {
      text: message
    }
  )
end

def fb_send_pic(recipient, img_url)
  Bot.deliver(
    recipient: recipient,
    message: {
      attachment: {
        type: 'image',
        payload: {
          url: img_url
        }
      }
    }
  )
end


# TODO: make btns optional
def fb_send_generic(recipient, title, img_url, btns)
  Bot.deliver(
    recipient: recipient,
      message: {
        attachment: {
          type:'template',
          payload:{
            template_type: 'generic',
            elements: [
              {   
                title: title,
                image_url: img_url,
                buttons: btns
              }
            ]
          }
        }
      }
  )
end

def get_fb_name(user_id)
  HTTParty.get("https://graph.facebook.com/v2.6/#{user_id['id']}?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}")
end

def fb_send_arbitrary(arb)
  Bot.deliver(arb)
end


DEMO    = /demo/i
DAY_ONE = /day1/i # ignore case and spaces
JOIN    = /join/i
INTRO   = 'INTRO'

def register_user(recipient)
    # save user in the database.
    begin
      users = DB[:users] 
      begin
        fb_name = HTTParty.get("https://graph.facebook.com/v2.6/#{recipient['id']}?fields=first_name,last_name&access_token=#{ENV['FB_ACCESS_TKN']}")
        name = fb_name["first_name"] + " " + fb_name["last_name"]
      rescue HTTParty::Error
        name = ""
      else
        puts "successfully found name"
      end

      begin 
        users.insert(:name => name, :fb_id => recipient["id"])
        puts "inserted #{name}:#{recipient} into the users table"
      rescue Sequel::UniqueConstraintViolation => e
        p e.message
        puts "did not insert, already exists in db"
      rescue Sequel::Error => e
        p e.message
        puts "failure"
      end
    rescue Sequel::Error => e
      p e.message
    end
end


Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"

  case message.text
  when DAY_ONE
    day1(message.sender, "0_3_3")
  when DEMO
  	intro(message.sender)
  when JOIN     
    fb_send_txt( message.sender, 
      "You're enrolled! Get ready for free stories!"
    )
  else 
    tuser = get_fb_name(message.sender)
    fb_send_txt( message.sender, 
      "Thanks, #{tuser['first_name']}! I’ll send your message to Ms. Stobierski to see next time she’s on her computer."
    )
  end
end


Bot.on :postback do |postback|

  case postback.payload
  when INTRO
    register_user(postback.sender)
    day1(postback.sender, "0_3_3")
  when /^[0-9]_[0-9]_[0-9]$/
    day1(postback.sender, postback.payload)
  end
end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end




