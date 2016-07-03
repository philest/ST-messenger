# require 'spec_helper'
# require 'clock'
# require 'rack-test'
# require 'workers/schedule_worker'
# require 'timecop'
# # require_relative '../models/story'

# describe Clockwork do

# 	before(:all) do
# 		before(:all) do
# 			WebMock.disable_net_connect!(allow_localhost:true)
# 		end
# 	end

# 	before(:each) do

# 		Sidekiq::Worker.clear_all
# 		@time = Time.new(2016, 6, 24, 23, 0, 0, 0) # with 0 utc-offset
# 		@time_range = 10.minutes.to_i
# 		@interval = @time_range / 2.0
# 		Timecop.freeze(@time)
# 	end

# 	context "scheduling ScheduleWorker jobs" do
# 		# Sidekiq::Testing::fake! do
# 		# 	expect {
				
# 		# 	}

# 		# end

# 	end


# 	context "scheduling enrollment post requests" do


# 	end

# end