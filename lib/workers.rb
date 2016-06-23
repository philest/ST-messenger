require 'sidekiq'
require 'active_support/time'
require_relative "../config/environment"

# load all of the scripts!

# The scripts can now all be accessed with
# Birdv::DSL::StoryTimeScript.scripts, which returns a hash table of scripts
require_relative 'bot/dsl'
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/sequence_scripts/*")
			.each {|f| require_relative f }


# get workers (must happen after the StoryTimeScripts are loaded)
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/workers/*")
			.each {|f| require_relative f }

