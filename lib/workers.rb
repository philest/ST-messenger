require 'sidekiq'
require 'active_support/time'
require 'rack'
require 'httparty'

require_relative '../config/environment'
require_relative '../config/initializers/redis'


redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/12'
# hopefull this will work out
# I'm giving 6 to puma and 1 to clock
Sidekiq.configure_client do |config|
    config.redis = { url: redis_url, size: 6 }
end

Sidekiq.configure_server do |config|
    config.redis = { url: redis_url, size: 8 }
    config.average_scheduled_poll_interval = 4
    config.error_handlers << Proc.new { |ex,ctx_hash| Airbrake.notify(ex, ctx_hash) }
end

# load all of the scripts!

# The scripts can now all be accessed with
# Birdv::DSL::StoryTimeScript.scripts, which returns a hash table of scripts

require_relative 'bot/curricula'
Birdv::DSL::Curricula.load

require_relative 'bot/dsl'

puts Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/sequence_scripts/*")

# story_count
$story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/sequence_scripts/*")
                .inject(0) do |sum, n|
                  if /\d+\.rb/.match n
                    sum + 1
                  else  
                    sum
                  end
                end

$sms_story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/sms_sequence_scripts/*")
                .inject(0) do |sum, n|
                  if /\d+\.rb/.match n
                    sum + 1
                  else  
                    sum
                  end
                end

Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/sms_sequence_scripts/*")
			.each {|f| require_relative f }

Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/feature_sequence_scripts/*")
      .each {|f| require_relative f }

Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/sequence_scripts/*")
			.each {|f| require_relative f }


# get workers (must happen after the StoryTimeScripts are loaded)
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/workers/*")
			.each {|f| require_relative f }

