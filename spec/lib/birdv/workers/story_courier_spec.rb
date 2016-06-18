require 'spec_helper'
Sidekiq::Testing.fake!
require 'timecop'
require 'birdv/workers/story_courier'

describe ScheduleWorker do
	before(:each) do
		# clean everything up
		DatabaseCleaner.clean
		Sidekiq::Worker.clear_all

		@time = Time.new(2016, 6, 24, 23, 0, 0, 0) # with 0 utc-offset
		@interval = 5
		Timecop.freeze(@time)

		@on_time = User.create(:send_time => Time.now)
		# puts "on_time = #{@on_time.send_time}"
		# 6:55:00 
		@just_early = User.create(:send_time => Time.now - @interval.minutes)
		# puts "just_early = #{@just_early.send_time}"
		#  7:04:59pm
		@just_late = User.create(:send_time => Time.now + (@interval-1).minutes + 59)
		# puts "just_late = #{@just_late.send_time}"
		# 6:54:59
		@early = User.create(:send_time => Time.now - (@interval+1).minutes + 59)
		# puts "early = #{@early.send_time}"
		# 7:05
		@late = User.create(:send_time => Time.now + @interval.minutes)
		# puts "late = #{@late.send_time}"
	end

	after(:each) do
		DatabaseCleaner.clean
	end

	context "timezone conversions", :zone => true do
		before(:each) do
			@summer, @winter = @time, @time + 6.months
			@s = ScheduleWorker.new
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


	context "#self.within_time_range" do
		it "converts timezones properly" do 
			summer = @time
			winter = @time + 6.months
			s = ScheduleWorker.new
			# puts "time = #{Time.now.utc}"
			# puts "enrolled_on = #{@on_time.enrolled_on}"
			# summer -> summer
			expect(s.adjust_tz(@on_time)).to eq(@on_time.send_time)
			# winter -> summer
			expect(s.adjust_tz(@on_time)).to eq(@on_time.send_time + 1.hour)

			user = User.create(:send_time => Time.now)
			expect(s.adjust_tz(user)).to eq(user.send_time)			

			Timecop.freeze(summer)
			expect(s.adjust_tz(user)).to eq(user.send_time - 1.hour)
		end



		it "returns true for users within the time interval at a given time" do 
			# just_early = Time.new(2016, 6, 24, 18, 60 - @interval)
			just_early = Time.now - @interval.minutes
			expect(ScheduleWorker.within_time_range(just_early, @interval)).to be true
			
			# just_late = Time.new(2016, 6, 24, 19, @interval - 1, 59)
			just_late = Time.now + (@interval.minutes + 59)
			expect(ScheduleWorker.within_time_range(just_late, @interval)).to be true
		end

		it "returns false for users outside the time interval at a given time" do
			# early = Time.new(2016, 6, 24, 18, 60-@interval-1, 59)
			early = Time.now - (5.minutes + 1)
			expect(ScheduleWorker.within_time_range(early, @interval)).to be false
			
			# late = Time.new(2016, 6, 24, 19, @interval)
			late = Time.now + 5.minutes
			expect(ScheduleWorker.within_time_range(late, @interval)).to be false
		end
	end

	it "gets users whose send_time is between 6:55:00 and 7:04:59 and calls StoryCourier on them" do
		users = [@on_time] + @just_early + @just_late
		filtered = ScheduleWorker.filter_users(@time, @interval)
		expect(filtered.size).to eq(users.size)
		# we want filter_uses to return the SQL rows
		expect(filtered.to_set).to eq(users.to_set)
	end

	it "does not get users whose send_time is at 7:05 or 6:54:59 and calls StoryCourier on them" do
		users = [@early] + [@late]
		filtered = ScheduleWorker.filter_users(@time, @interval)
		for user in users
			expect(filtered).not_to include(user)
		end
	end

	it "calls StoryCourier on all the right people" do
		users = [@on_time] + @just_early + @just_late

		expect {
		  ScheduleWorker.perform_async
		}.to change(ScheduleWorker.jobs, :size).by(users.size)

		# specify exact arguments and people on this one...
		for user in users
			expect(StoryCourier).to receive(:perform_async).with(user.name, user.fb_id, "some_title", 2).once
		end
	end

	# it "calls StoryCourier for users whose send_time is within the proper time interval" do
	# 	expect(StoryCourier).to receive(:perform_async)
	# 	ScheduleWorker.new.perform
	# end

	it "does not call StoryCourier for anyone twice in a row" do

	end
end
