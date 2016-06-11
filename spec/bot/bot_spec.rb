require 'spec_helper'
require 'bot/bot'
# require_relative '../models/story'

describe "Bot" do
	context "When adding new users to the database" do
		it "should successfully connect to the database" do

			# expect()
		end

		it "should rescue an exception upon failure to connect to the db" do 
		end

		it "should successfully add a user to the database if the user's Facebook id and phone number are unique" do
		end

		it "should throw a database exception when either the FB id or the phone number are not unique" do
		end

		it "should rescue the db exception in the above instance" do
		end
	end
end