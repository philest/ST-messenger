require 'uri'
require 'redis'

puts "THIS REDIS SHIT SHOULD ONLY BE CALLED TWICE!"

redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/12'
uri = URI.parse(redis_url)
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
