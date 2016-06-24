require 'sidekiq'
require 'active_support/time'
require_relative "../config/environment"

redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/12'
# hopefull this will work out
# I'm giving 6 to puma and 1 to clock
Sidekiq.configure_client do |config|
    config.redis = { url: redis_url, size: 7 }
end

Sidekiq.configure_server do |config|
    config.redis = { url: redis_url, size: 8 }
end


# load all of the scripts!

# The scripts can now all be accessed with
# Birdv::DSL::StoryTimeScript.scripts, which returns a hash table of scripts
require_relative 'bot/dsl'
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/sequence_scripts/*")
			.each {|f| require_relative f }


# get workers (must happen after the StoryTimeScripts are loaded)
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/workers/*")
			.each {|f| require_relative f }

