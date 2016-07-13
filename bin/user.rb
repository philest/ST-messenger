require 'httparty'
require 'dotenv'
Dotenv.load

uri = "https://graph.facebook.com/v2.6/" + ENV["DAVID"]

query = "fields=first_name,last_name,locale,timezone,gender"

# first_name,last_name,locale,timezone,gender

# fb_name = JSON.parse HTTParty.get("https://graph.facebook.com/v2.6/#{ENV["DAVID_QUAILTIME"]}?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}").body

puts HTTParty.get("https://graph.facebook.com/v2.6/10209967651611613?access_token=#{ENV['FB_ACCESS_TKN']}&fields=first_name,last_name,profile_pic,locale,timezone,gender").body.to_json

# fb_name = HTTParty.get("https://graph.facebook.com/v2.6/bad_id?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}").body.to_json

# puts fb_name
# puts HTTParty.get("#{uri}?#{query}&access_token=#{ENV['FB_ACCESS_TKN']}")
# 
