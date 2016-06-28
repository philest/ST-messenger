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
	 
   time_range = 5.minutes
	 interval   = time_range.to_i / 2.0

  	every time_range, 'check.db' do 
  		# TODO remove .minutes! should be in seconds
  		ScheduleWorker.perform_async(interval)
  	end


    enrollment_time_range = 1.hour
    enrollment_interval   = enrollment_time_range.to_i / 2.0

  	every enrollment_time_range, 'enroll.db', do
  		HTTParty.post('https://st-enroll.herokuapp.com/enroll', 
        body: {
          time_interval: enrollment_interval
        }
      )
  	end
end
