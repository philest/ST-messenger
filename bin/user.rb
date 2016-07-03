require 'httparty'
require 'dotenv'
Dotenv.load

uri = "https://graph.facebook.com/v2.6/" + ENV["PHIL_QUAILTIME"]

query = "fields=first_name,last_name,locale,timezone,gender"

# first_name,last_name,locale,timezone,gender

fb_name = JSON.parse HTTParty.get("https://graph.facebook.com/v2.6/#{ENV["PHIL_QUAILTIME"]}?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}").body

puts fb_name
# puts HTTParty.get("#{uri}?#{query}&access_token=#{ENV['FB_ACCESS_TKN']}")



      def fb_get_user(id)
        begin
          fb_name = JSON.parse HTTParty.get("https://graph.facebook.com/v2.6/#{id}?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}").body
        rescue HTTParty::Error
          name = ""
        end
      end

      def fb_get_name_honorific(id)
        fb_name = fb_get_user(id)
        if fb_name['last_name']== ''
          return ""
        else
          honorific = "Mx."
          case fb_name['gender']
          when 'male'
            honorific = "Mr."
          when 'female'
            honorific = "Ms."
          end
          return "#{honorific} #{fb_name['last_name']}"
        end
      end


# puts fb_get_user(ENV["PHIL_QUAILTIME"])

puts fb_get_name_honorific(ENV["PHIL_QUAILTIME"])