require 'spec_helper'
Sidekiq::Testing.inline!
require 'timecop'
require 'birdv/workers/story_courier'

describe ScheduleWorker do
	before(:all) do
		@time = Time.new(2016, 6, 24, 19)
		@interval = 5
		Timecop.freeze(@time)

		@on_time = User.create
		# 6:55:00 ... 
		@just_early = 10.times.map do |i|
			User.create(:send_time => DateTime.new(2016, 6, 24, 18, 55, i))
		end
		# ... 7:04:59pm
		@just_late = 10.times.map do |i|
			User.create(:send_time => DateTime.new(2016, 6, 24, 19, 4, 59 - i))
		end
		# 7:55
		@early = User.create(:user, :send_time => DateTime.new(2016, 6, 24, 18, 55))
		@late = User.create(:user, :send_time => DateTime.new(2016, 6, 24, 19, 5))
	end

	it "gets users whose send_time is between 6:55:00 and 7:04:59 and calls StoryCourier on them" do
		users = [@on_time] + @just_early + @just_late
		filtered = ScheduleWorker.filter_users(time, interval)
		expect(filtered.size).to eq(users.size)
		# we want filter_uses to return the SQL rows
		expect(filtered.to_set).to eq(users.to_set)
	end

	it "does not get users whose send_time is at 7:05 or 6:54:59 and calls StoryCourier on them" do
		users = @early + @late
		filtered = ScheduleWorker.filter_users(time, interval)
		for user in users
			expect(filtered).not_to include(user)
		end
	end

	it "calls StoryCourier on all the right people" do
		users = [@on_time] + @just_early + @just_late
		expect(StoryCourier).to receive(:perform_async).exactly(users.size).times
		StoryWorker.perform_async
	end

	it "calls StoryCourier for users whose send_time is within the proper time interval" do
		expect(StoryCourier).to receive(:perform_async)
		StoryWorker.perform_async
	end


	it "does not call StoryCourier for anyone twice in a row" do

	end
end
