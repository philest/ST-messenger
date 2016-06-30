require 'spec_helper'
require 'timecop'
require 'active_support/time'
require 'workers/bot_worker'
require 'bot/dsl'

describe BotWorker do

	let (:usr) {User.create(:fb_id=>@usr_fb_id,:send_time => Time.now, :story_number => @starting_story_number)}

	before(:all) do
		# some config var :P
		@starting_story_number = 4
		@usr_fb_id						 = '12345'

		# get pointer to scripts
		@scripts = Birdv::DSL::StoryTimeScript.scripts

		# load up some scripts!
		Birdv::DSL::StoryTimeScript.new 'day3' do
			sequence 'one' do end
			sequence 'two' do end
		end
		Birdv::DSL::StoryTimeScript.new 'day4' do
			sequence 'one' do end
			sequence 'two' do end			
		end
		Birdv::DSL::StoryTimeScript.new 'day5' do
			sequence 'one' do end
			sequence 'two' do end		
		end
	end

	before(:each) do
		Sidekiq::Worker.clear_all
		usr.save
	end

	context 'button press' do
		before(:example) do
			response = "{\"recipient_id\":\"10209967651611613\",\"message_id\":\"mid.1467225743455:2497dbcb4b07e68745\"}"

			stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
	        with(:body => "{\"recipient\":{\"id\":\"12345\"},\"message\":{\"text\":\"Excited for more stories? We'll send some more your way tomorrow night!\"}}",
	             :headers => {'Content-Type'=>'application/json'}).
	        to_return(:status => 200, :body => response)
		end

		it 'adds new log entries when press a day3 button' do
			expect {
				Sidekiq::Testing.inline! do
					BotWorker.perform_async('12345','day3','two')
				end
			}.to change{ButtonPressLog.count}.by(1)
		end

		# it 'does not send more stories when buttons are pressed within two minutes of each other' do
		# 	expect {
		# 		Sidekiq::Testing.inline! do
		# 			5.times { BotWorker.perform_async('12345','day3','two') }
		# 		end
		# 	}.to change{ButtonPressLog.count}.by(1)
		# end

		# it 'sends repeat stories if user presses button after two minutes' do
		# 	require 'timecop'

		# 	expect {
		# 		Sidekiq::Testing.inline! do
		# 			5.times do
		# 				Timecop.travel(Time.now + 3.minutes)
		# 				BotWorker.perform_async('12345','day3','two')
		# 			end

		# 		end
		# 	}.to change{ButtonPressLog.count}.by(5)
		# end

		it 'does not update story_number when user is presses button from old script' do
			expect {
				Sidekiq::Testing.inline! do
					5.times {BotWorker.perform_async('12345','day3','two')}
				end
			}.to_not change{usr.story_number}		
		end

		it 'pressing day4 button jumps story_number to next day (day 5)' do
			expect {
				Sidekiq::Testing.inline! do
					BotWorker.perform_async('12345','day4','one')
				end
			}.to change{User.where(:fb_id=>@usr_fb_id).first.story_number}.to 5	
		end
	end
end