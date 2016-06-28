require 'spec_helper'
require 'timecop'
require 'active_support/time'
require 'workers/schedule_worker'
describe ScheduleWorker do
	before(:each) do
		# clean everything up
		# DatabaseCleaner.clean
		Sidekiq::Worker.clear_all

		@time = Time.new(2016, 6, 24, 23, 0, 0, 0) # with 0 utc-offset
		@time_range = 10.minutes.to_i
		@interval = @time_range / 2.0
		Timecop.freeze(@time)

		@s = ScheduleWorker.new

		@on_time = User.create(:send_time => Time.now, :story_number => 2)
		# puts "on_time = #{@on_time.send_time}"
		# 6:55:00 
		@just_early = User.create(:send_time => Time.now - @interval, :story_number => 2)
		# puts "just_early = #{@just_early.send_time}"
		#  7:04:59pm
		@just_late = User.create(:send_time => Time.now + (@interval-1.minute) + 59.seconds, :story_number => 2)
		# puts "just_late = #{@just_late.send_time}"
		# 6:54:59
		@early = User.create(:send_time => Time.now - (@interval+1.minute) + 59.seconds, :story_number => 2)
		# puts "early = #{@early.send_time}"
		# 7:05
		@late = User.create(:send_time => Time.now + @interval, :story_number => 2)
		# puts "late = #{@late.send_time}"
	end

	after(:each) do
		Timecop.return
	end

	# after(:each) do
	# 	DatabaseCleaner.clean
	# end

	context "timezone conversion function", :zone => true do
		before(:each) do
			@summer, @winter = @time, @time + 6.months
		end

		it "handles summer-summer and winter-winter cases (DST)" do
		# when the user enrolled in the summer and it's currently summer
			Timecop.freeze(@summer)
			user = User.create(:send_time => Time.now)
			expect(@s.adjust_tz(user)).to eq(user.send_time)
			# winter-winter case
			Timecop.freeze(@winter)
			user = User.create(:send_time => Time.now) # enrolled_on field is wintertime
			expect(@s.adjust_tz(user)).to eq(user.send_time)
		end

		it "subtracts an hour from the UTC clock when it's summer and the user enrolled during the winter" do
		# when the user enrolled in the winter and it's currently summer
			Timecop.freeze(@winter)
			user = User.create(:send_time => Time.now)
			Timecop.freeze(@summer)
			expect(@s.adjust_tz(user)).to eq(user.send_time - 1.hour)
		end

		it "adds an hour to the UTC clock when it's winter and the user enrolled during the summer" do 
		# when the user enrolled in the summer and it's currently winter
			Timecop.freeze(@summer)
			user = User.create(:send_time => @summer)
			Timecop.freeze(@winter)
			expect(@s.adjust_tz(user)).to eq(user.send_time + 1.hour)
		end
	end


	context "within_time_range function", :range => true do

		it "returns true for users within the time interval at a given time" do 
			# just_early = Time.new(2016, 6, 24, 18, 60 - @interval)
			# just_early = Time.now - @interval
			expect(@s.within_time_range(@just_early, @interval)).to be true
			
			# just_late = Time.new(2016, 6, 24, 19, @interval - 1, 59)
			# just_late = Time.now + (@interval + 59)
			expect(@s.within_time_range(@just_late, @interval)).to be true
		end

		it "returns false for users outside the time interval at a given time" do
			# early = Time.new(2016, 6, 24, 18, 60-@interval-1, 59)
			# early = Time.now - (5 + 1)
			expect(@s.within_time_range(@early, @interval)).to be false
			
			# late = Time.new(2016, 6, 24, 19, @interval)
			# late = Time.now + 5
			expect(@s.within_time_range(@late, @interval)).to be false
		end

		it "does not send messages to a user twice" do
			DB[:users].delete # clean database
			user = User.create(:send_time => Time.now + @interval - 1.second, :story_number => 2)
			expect(@s.within_time_range(user, @interval)).to be true
			Timecop.freeze(Time.now + @time_range)
			expect(@s.within_time_range(user, @interval)).to be false			
		end

	end

	context "filtering users", :filter => true do
		it "gets users whose send_time is between 6:55:00 and 7:04:59" do
			users = [@on_time, @just_early, @just_late]
			filtered = @s.filter_users(@time, @interval)
			expect(filtered.size).to eq(3)
			# we want filter_uses to return the SQL rows
			expect(filtered.to_set).to eq(users.to_set)
		end

		it "does not get users whose send_time is at 7:05 or 6:54:59" do
			users = [@early, @late]
			filtered = @s.filter_users(@time, @interval)
			for user in users
				expect(filtered).not_to include(user)
			end
		end

		it "calls StartDayWorker the correct number of times" do
			users = [@on_time, @just_early, @just_late]
			expect(ScheduleWorker.jobs.size).to eq(0)
			
			Sidekiq::Testing.fake! do
				expect {
				  ScheduleWorker.new.perform(@interval)
				  ScheduleWorker.drain
				}.to change(StartDayWorker.jobs, :size).by(3)
			end
		end

		it "does NOT call StartDayWorker when users are at day 1" do
			DB[:users].delete # clean database
			user = User.create(:send_time => Time.now, :story_number => 1)
			expect(ScheduleWorker.jobs.size).to eq(0)

			Sidekiq::Testing.fake! do
				expect {
				  ScheduleWorker.new.perform(@interval)
				  ScheduleWorker.drain
				}.to change(StartDayWorker.jobs, :size).by(0)
			end
		end

		it "calls StartDayWorker on all the right people" do
			# specify exact arguments and people on this one...
			users = [@on_time, @just_early, @just_late]
			for user in users
				expect(StartDayWorker).to receive(:perform_async).with(user.fb_id, user.story_number).once
			end

			Sidekiq::Testing.inline! do
				ScheduleWorker.perform_async
			end
		end
	end
end
