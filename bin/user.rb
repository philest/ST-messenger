require 'httparty'
require 'dotenv'
Dotenv.load

uri = "https://graph.facebook.com/v2.6/" + ENV["DAVID_QUAILTIME"]

query = "fields=first_name,last_name,locale,timezone,gender"

# first_name,last_name,locale,timezone,gender

fb_name = JSON.parse HTTParty.get("https://graph.facebook.com/v2.6/#{ENV["PHIL_QUAILTIME"]}?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}").body

puts fb_name
# puts HTTParty.get("#{uri}?#{query}&access_token=#{ENV['FB_ACCESS_TKN']}")
# 
