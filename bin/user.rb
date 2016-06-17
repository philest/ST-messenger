require 'httparty'
require 'dotenv'
Dotenv.load

uri = "https://graph.facebook.com/v2.6/" + ENV["DAVID"]

query = "fields=timezone"

# first_name,last_name,locale,timezone,gender

puts HTTParty.get("#{uri}?#{query}&access_token=#{ENV['FB_ACCESS_TKN']}")
