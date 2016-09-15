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
end


