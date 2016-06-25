require "clockwork"
require "sequel"
require 'sidekiq'
require 'active_support/time'

# we have to open this connection to load the models, which is an unfornate thing that 
# must be done by us :(
DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require', :max_connections => 1)

# load models
models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }

# we only need the schedule worker
require_relative 'workers'


module Clockwork
	interval = 30
  	every interval.seconds, 'check.db' do 
  		# TODO change this back to INTERVAL!!!!
  		ScheduleWorker.perform_async(1.day.to_i)
  	end
end
