require 'spec_helper'
require 'bot/bot'
# require_relative '../models/story'

describe "Bot" do

	context "user-fb_id matching", :matching => true do
		before(:each) do
			@user = User.create(:child_name => "David McPeek", :phone => "8186897323")
			@fb_id = ENV["DAVID"]
			@recipient = { id: @fb_id }
		end

		it "creates a user with just a fb_id attribute on failure" do 
			bad_id = { id: "bad!" }
			expect(register_user(bad_id)).to raise_exception(HTTParty::Error)
		end

	end

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