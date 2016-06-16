require 'spec_helper'
require 'bot/bot'
# require_relative '../models/story'

describe "Bot" do

	describe '#fb_send_txt' do

	

	end

	context "When adding new users to the database" do
		it "successfully connects to the database" do

			# expect()
		end

		it "rescues an exception upon failure to connect to the db" do 
		end

		it "adds a user to the db if the user's FB id and phone number are unique" do
		end

		it "throws a db exception when either the FB id or the phone number are not unique" do
		end

		it "rescues the db exception in the above instance" do
		end
	end
end