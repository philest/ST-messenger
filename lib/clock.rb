require "clockwork"
require "sequel"
require 'sidekiq'
require 'active_support/time'
require 'httparty'

require_relative '../config/environment'
get_db_connection( max_connections = 1 )
# load our workers!
require_relative 'workers'

require_relative '../config/initializers/airbrake'

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

    # we want once per day in the morning for teachers to be notified
    # we don't know what timezone the teacher's in, but it's between -8 and -5

    # so every hour, we check if we're within the hour of 4am california time.
    # that means that everyone will get their notification before 7am, which is what we want. 


    every 1.hour, 'teacher.notify' do
      if Time.now.utc.hour == 12 # 4am PST
        Teacher.each do |t|
          # we don't want any repeats
          if (Time.now.utc - t.notified_on.utc) > 2.hours
            NotifyTeacherWorker.perform_async(t.id)
          end
        end

      end

    end # teacher.notify



end


