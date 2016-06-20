require "clockwork"
require 'sidekiq'
require 'active_support/time'

# load all of the scripts!

# The scripts can now all be accessed with
# StoryTimeScript.scripts, which returns a hashtable of scripts
require_relative 'bot/dsl'
# TODO i have no idea how I was actually navigate to the correct path
Dir.glob("#{File.expand_path("", File.dirname(__FILE__))}/sequence_scripts/*")
			.each {|f| require_relative f }


# get workers (must happen after the scripts are loaded)
require_relative 'worker'

# cronjob
module Clockwork
  every 10.seconds, 'check.db' do 
  	ScheduleWorker.perform_async
  end
end
