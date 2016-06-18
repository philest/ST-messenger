require 'spec_helper'
Sidekiq::Testing.fake!
require 'timecop'
require 'birdv/workers/story_courier'

describe ScheduleWorker do
	before(:each) do
		# clean everything up
		DatabaseCleaner.clean
		Sidekiq::Worker.clear_all

		@time = Time.new(2016, 6, 24, 19)
		@interval = 5
		Timecop.freeze(@time)

		@on_time = User.create(:send_time => Time.new(2016, 6, 24, 19))
		# 6:55:00 ... 
		@just_early = 10.times.map do |i|
			User.create(:send_time => Time.new(2016, 6, 24, 18, 60 - @interval, i))
		end
		# ... 7:04:59pm
		@just_late = 10.times.map do |i|
			User.create(:send_time => Time.new(2016, 6, 24, 19, @interval - 1, 59 - i))
		end
		# 7:55
		@early = User.create(:send_time => Time.new(2016, 6, 24, 18, 60-@interval-1, 59))
		@late = User.create(:send_time => Time.new(2016, 6, 24, 19, @interval))
	end

	after(:each) do
		DatabaseCleaner.clean
	end

	context "#self.within_time_range" do
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
