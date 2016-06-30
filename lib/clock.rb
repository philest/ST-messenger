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

    
    sched_pd = 5                     # (i.e. 'schedule period')
	  sched_range  = sched_pd / 2.0    # (i.e. 'schedule range')

  	every sched_pd.minutes, 'check.db' do 
  		# TODO: remove .minutes! should be in seconds
  		ScheduleWorker.perform_async(sched_range)
  	end


    enrollment_time_pd = 10
    enrollment_range   = enrollment_time_pd / 2.0

  	every enrollment_time_pd.minutes, 'enroll.db' do
     HTTParty.post('https://st-enroll.herokuapp.com/enroll', 
        body: {
          time_interval: enrollment_range
        }.to_json,
        :headers => { 'Content-Type' => 'application/json' }
      )
  	end
end

 






