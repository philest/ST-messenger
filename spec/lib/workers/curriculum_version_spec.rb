require 'spec_helper'
require 'timecop'
require 'active_support/time'
require 'workers/bot_worker'
require 'bot/dsl'

describe "curriculum versions" do
	# let (:user1) { User.create(curriculum_version: 0) }
	# let (:user2) { User.create(curriculum_version: 1) }

	# before(:all) do
	# 	# some config var :P
	# 	@starting_story_number 				= 1
	# 	@usr_fb_id						 	= '12345'

	# 	# get pointer to scripts
	# 	@scripts = Birdv::DSL::StoryTimeScript.scripts

	# 	# load up some scripts!
	# 	Birdv::DSL::StoryTimeScript.new 'day1' do
	# 		day 1
	# 		sequence 'one' do |recipient|
	# 			send_story recipient
	# 		end
	# 	end
	# 	Birdv::DSL::StoryTimeScript.new 'day2' do
	# 		day 2
	# 		sequence 'one' do |recipient|
	# 			send_story recipient
	# 		end			
	# 	end
	# 	Birdv::DSL::StoryTimeScript.new 'day3' do
	# 		day 3
	# 		sequence 'one' do |recipient|
	# 			send_story recipient
	# 		end		
	# 	end
	# end

	# before(:each) do
	# 	Sidekiq::Worker.clear_all
	# 	usr.save
	# end

	# context "getting rows from CSV file" do
	# 	@scripts.load_curriculum_versions("../../spec/lib/test_version_files")

	# 	# why is this returning nil? 
	# 	puts @scripts.curriculum_versions
	# end

	# context "sending different story 1" do
	# 	it "sends coon story to user1" do
	# 		# .run_sequence on user fb_id
	# 		# expect that the picture function should receive urls of a certain type
	# 		day1 = @scripts['day1']
			

	# 		# expect(day1).to receive(:picture).with()

	# 	end

	# 	it "sends bird story to user2" do

	# 	end

	# end
end



















