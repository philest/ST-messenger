require 'spec_helper'
require 'timecop'
require 'active_support/time'
require 'workers/message_worker'
require 'bot/dsl'

describe MessageWorker do

	let (:usr) {User.create(:fb_id=>@usr_fb_id,:send_time => Time.now, :story_number => @starting_story_number)}

	before(:all) do
		# some config var :P
		@starting_story_number = 4
		@usr_fb_id						 = '12345'

		# get pointer to scripts
		@scripts = Birdv::DSL::ScriptClient.scripts['fb']

		# load up some scripts!
		Birdv::DSL::ScriptClient.new_script 'day3' do
			sequence 'one' do end
			sequence 'two' do end
		end
		Birdv::DSL::ScriptClient.new_script 'day4' do
			sequence 'one' do end
			sequence 'two' do end			
		end
		Birdv::DSL::ScriptClient.new_script 'day5' do
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
					MessageWorker.perform_async('12345','day3','two')
				end
			}.to change{ButtonPressLog.count}.by(1)
		end


		# it 'sends the story once' do
		# 	# TODO: need to figure out a way to test this
		# 	expect {
		# 		Sidekiq::Testing.inline! do
		# 			5.times { MessageWorker.perform_async('12345','day3','two') }
		# 		end
		# 	}.to change{ButtonPressLog.count}.by(1)

		# end

		it 'does not send story, but do log button presses' do
			require 'timecop'

			expect {
				Sidekiq::Testing.inline! do
					5.times do
						Timecop.travel(Time.now + 3.minutes)
						MessageWorker.perform_async('12345','day3','two')
					end
				end
			}.to change{ButtonPressLog.count}.by(5)
		end

		it 'does not update story_number when user is presses button from old script' do
			expect {
				Sidekiq::Testing.inline! do
					5.times {MessageWorker.perform_async('12345','day3','two')}
				end
			}.to_not change{usr.story_number}		
		end

		# this should only be done by scheduler
		it 'pressing day4 button DOES NOT jump story_number to next day (day 5)' do
			expect {
				Sidekiq::Testing.inline! do
					MessageWorker.perform_async('12345','day4','one')
				end
			}.not_to change{User.where(:fb_id=>@usr_fb_id).first.story_number}	
		end
	end
end