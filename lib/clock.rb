require "clockwork"
require "sequel"
require 'sidekiq'
require 'active_support/time'
require 'httparty'

#
# we have to open this connection to load the models, which is a very unfortunate thing that 
# must be done by us :(
#
ENV["RACK_ENV"] ||= "development"
puts "loading #{ENV['RACK_ENV']} db for clock..."
pg_driver = RUBY_PLATFORM == 'java' ? 'jdbc:' : ''

case ENV["RACK_ENV"]
when "development", "test"
  require 'dotenv'
  Dotenv.load
  db_url    = "#{pg_driver}#{ENV['PG_URL_LOCAL']}"
  DB        = Sequel.connect(db_url)
when "production"
  db_url    = "#{pg_driver}#{ENV['PG_URL']}"
  DB        = Sequel.connect(db_url, :max_connections => (1))
end

DB.timezone = :utc

models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }


# load our workers!
require_relative 'workers'

module Clockwork

    #
    # send out stories every sched_pd seconds
    #
    sched_pd = 5.minutes             # (i.e. 'schedule period')
	  sched_range  = sched_pd / 2.0    # (i.e. 'schedule range')

  	every sched_pd, 'check.db' do 
      puts "sched_pd = #{sched_pd}"
      puts "sched_range = #{sched_range}"
  		# TODO: remove .minutes! should be in seconds
  		ScheduleWorker.perform_async(sched_range)
  	end

    #
    # ping the enrollment server every enrollment_time_pd seconds 
    # to check if anyone needs to be sent an enrollment text
    #
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

end


