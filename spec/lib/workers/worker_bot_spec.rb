require 'spec_helper'
require 'timecop'
require 'active_support/time'
require 'workers/worker_bot'
require 'bot/dsl'

describe StoryTimeScriptWorker do

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
		it 'adds new log entries when press a day3 button' do
			expect {
				Sidekiq::Testing.inline! do
					5.times {StoryTimeScriptWorker.perform_async('12345','day3','two')}
				end
			}.to change{ButtonPressLog.count}.by(5)
		end

		it 'does not update story_number when user is presses button from old script' do
			expect {
				Sidekiq::Testing.inline! do
					5.times {StoryTimeScriptWorker.perform_async('12345','day3','two')}
				end
			}.to_not change{usr.story_number}		
		end

		it 'pressing day4 button jumps story_number to next day (day 5)' do
			expect {
				Sidekiq::Testing.inline! do
					StoryTimeScriptWorker.perform_async('12345','day4','one')
				end
			}.to change{User.where(:fb_id=>@usr_fb_id).first.story_number}.to 5	
		end
	end


end