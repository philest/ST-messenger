require 'facebook/messenger'
require 'activerecord-jdbcpostgresql-adapter' if RUBY_PLATFORM == 'java'
require 'sequel'
require 'httparty'

require_relative '../../config/environment'

Facebook::Messenger.configure do |config|
  config.access_token = ENV['FB_ACCESS_TKN']
  config.verify_token = ENV['FB_VERIFY_TKN']
end

include Facebook::Messenger
require_relative 'demo'
require_relative 'intro'

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


DEMO    = /demo/i
DAY_ONE = /day one/xi # ignore case and spaces
JOIN    = /join/i
INTRO   = 'INTRO'


Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"

  case message.text
  when DAY_ONE
    day1()
  when DEMO
  	demo(message)
  when JOIN     
    fb_send_txt( message.sender, 
      "You're enrolled! Get ready for free stories!"
    )
  else 
    fb_send_txt( message.sender, 
      "You say \"#{message.text}\". I say, \"QuailTime!\""
    )
  end
end


Bot.on :postback do |postback|

  case postback.payload
  when /^[0-9]_[0-9]_[0-9]$/
    intro(postback.sender)
  else
    fb_send_txt( postback.sender, postback.payload, 
      "lol what is that selection?"
    )    
  end
end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end




