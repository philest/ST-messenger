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
require_relative 'fb_helpers'
include Facebook::Messenger::Helpers
require_relative 'demo'
require_relative 'intro'
require_relative 'day1'

# aubrey 10209571935726081
# phil 10209486368143976
# david 10209967651611613

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

#
# handy bot helpers
#
STORY_BASE_URL = 'https://s3.amazonaws.com/st-messenger/'

# sends recipient the indicated story
# here's what this looks like:
# 
#
# NOTE: Indexes by 1 through end, because this is the format
# that inDesign
def send_story(recipient, library, title_url, num_pages)
  num_pages.times do |i|
    fb_send_pic(recipient, STORY_BASE_URL+"#{library}/#{title_url}/#{title_url}#{i+1}.jpg")
  end
end


def btn_json(title, btn_group, btn_num, bin)
  return {
    type:   'postback',
    title:  "#{title}",
    payload:"#{btn_group}_#{btn_num}_#{bin}" 
  }
end




def format_btns(btn_group, bin=7)
  arr_size = btn_group.size
  reversed_bin_str = ("%0#{arr_size}b" % bin).reverse

  selected_btns = eval("BTN_GROUP#{btn_group}").map.with_index do |e, i|
      [e,(2**i)]
  end

  formated_btns = selected_btns.map.with_index do |e,i|
    btn_json(e[0],btn_group,i,bin-e[1])
  end
end



#
# here's what this looks like:
# 
#

# e.g. of payload format:
# '3_1_2' = btn_group 3, button 1, binarystring 2
def story_btn(recipient, library, title, title_url, btn_group)
  formatted_btns = format_btns(btn_group)
  turl =  STORY_BASE_URL + "#{library}/#{title_url}/#{title_url}title.jpg"
  fb_send_template_generic(recipient, title, turl, formatted_btns)
end




def generate_btns(recipient, btn_group, message_text, bin=7)
  arr_size = btn_group.size
  reversed_bin_str = ("%0#{arr_size}b" % bin).reverse

  selected_btns = eval("BTN_GROUP#{btn_group}").map.with_index do |e, i|
    if (reversed_bin_str[i] == "1")
      [e,(2**i)]
    else
      []
    end
  end

  temp = selected_btns.map.with_index do |e,i|
    if !e.empty?
     btn_json(e[0],btn_group,i,bin-e[1])
    else
      []
    end
  end

  formatted_btns = temp.reject{ |c| c.empty? }

  btn_rqst= { recipient: recipient,
              message: {
                attachment: {
                  type: 'template',
                  payload: {
                    template_type:'button',
                    text: message_text,
                    buttons: formatted_btns
                  }
                }
              }
            }

  return btn_rqst
end






DEMO    = /demo/i
DAY_ONE = /day1/i # ignore case and spaces
JOIN    = /join/i
TENIMG  = /tenimg/i
INTRO   = 'INTRO'

puts "poop"

#
# i.e. when user sends the bot a message.
#
Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"

  case message.text
  when TENIMG
    10.times do 
    fb_send_pic(message.sender,'https://s3.amazonaws.com/st-messenger/day1/clouds/clouds1.jpg') end
  when DAY_ONE
    day1(message.sender, "0_3_3")
  when DEMO
  	intro(message.sender)
  when JOIN     
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

  case postback.payload
  when INTRO
    register_user(postback.sender)
    day1(postback.sender, "0_3_3")
  when /^[0-9]_[0-9]_[0-9]$/
    day1(postback.sender, postback.payload)
  end
end


#
# i.e. a reciept from facebook
#
Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end




