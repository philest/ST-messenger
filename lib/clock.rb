require "clockwork"
require "sequel"
require 'sidekiq'
require 'active_support/time'
require 'httparty'

# we have to open this connection to load the models, which is an unfornate thing that 
# must be done by us :(

ENV['RACK_ENV'] ||= 'development'
puts "loading #{ENV['RACK_ENV']} db for clock..."

case ENV['RACK_ENV']
when 'development', 'test'
  DB = Sequel.connect(ENV['DATABASE_URL'])
when 'production'
  DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require', :max_connections => 1)
end

DB.timezone = :utc

# load models
models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }

# we only need the schedule worker
require_relative 'workers'

module Clockwork

    sched_pd = 5.minutes             # (i.e. 'schedule period')
	  sched_range  = sched_pd / 2.0    # (i.e. 'schedule range')

  	every sched_pd, 'check.db' do 
      puts "sched_pd = #{sched_pd}"
      puts "sched_range = #{sched_range}"
  		# TODO: remove .minutes! should be in seconds
  		ScheduleWorker.perform_async(sched_range)
  	end

    enrollment_time_pd = 10.minutes
    enrollment_range   = enrollment_time_pd / 2.0

  	every enrollment_time_pd, 'enroll.db' do
      puts "enrollment_time_pd = #{enrollment_time_pd}"
      puts "enrollment_range = #{enrollment_range}"
     HTTParty.post('https://st-enroll.herokuapp.com/enroll', 
        body: {
          time_interval: enrollment_range
        }
      )
  	end

    i = 0
    every 3.second, 'timer' do
      # puts "#{i} mississippi"
      TestBot.perform_async(i, "hat")
      TestBot.perform_async(i, "hat")
      TestBot.perform_async(i, "hat")
      i += 1
    end


    # every 30.seconds, 'test.ass' do
    #   puts "testing this one thing..."
    #   TestBot.perform_in(15.seconds)
    # end




end















 






