require "clockwork"
require "sequel"
require 'sidekiq'
require 'active_support/time'
require 'httparty'

# we have to open this connection to load the models, which is an unfornate thing that 
# must be done by us :(
DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require', :max_connections => 1)
DB.timezone = :utc

# load models
models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }

# we only need the schedule worker
require_relative 'workers'


module Clockwork
	interval = 5.minutes
  	every interval, 'check.db' do 
  		# TODO remove .minutes! should be in seconds
  		ScheduleWorker.perform_async(interval.to_i)
  	end

  	every 1.day, 'enroll.db', :at => '23:00', :tz => 'UTC' do
  		HTTParty.get('https://st-enroll.herokuapp.com/enroll')
  	end
end
