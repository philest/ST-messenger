require 'spec_helper'
Sidekiq::Testing.inline!
require 'timecop'
require 'birdv/workers/story_courier'

describe StoryWorker do
	before(:all) do
		@time = Timecop


		@on_time = create(:user)
		# 6:55:5pm
		@just_early = 10.times.map do 
			build(:user, :send_time => DateTime.new(2016, 6, 24, 18, 55, 5))
		end
		# 7:04:55pm
		@just_late = 10.times.map do 
			build(:user, :send_time => DateTime.new(2016, 6, 24, 19, 4, 55))
		end
		# 7:55
		@early = 10.times.map do 
			build(:user, :send_time => DateTime.new(2016, 6, 24, 18, 55))
		end
	end

	it "gets users whose send_time is above "

	it "gets users whose send_time is within the proper time interval" do
		# 5 minute time interval

	end

	it "calls StoryCourier for users whose send_time is within the proper time interval" do 
		expect(StoryCourier).to receive(:perform_async)
		StoryWorker.perform_async
	end

	it "does not call StoryCourier for users whose send_time is within the proper time interval" do

	end

	it "does not call StoryCourier for anyone twice in a row" do

	end
end
