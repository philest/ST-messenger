require 'spec_helper'
require 'bot/bot'
# require_relative '../models/story'

describe "Bot" do
	context "user-fb_id matching", :matching => true do

		it "creates a user with just a fb_id attribute on failure" do 
			bad_id = { "id" => "bad_id" }
			register_user(bad_id)
			expect(User.count).to eq 1
			user = User.first
			expect(user.fb_id).to eq "bad_id"
			expect(user.name).to be_nil
			expect(user.child_name).to be_nil
			expect(user.phone).to be_nil
		end

		it "matches fb_id to existing user with the same last name in the db" do
			init = User.create(:child_name => "Galen McPeek", :phone => "8186897323")
			fb_id = ENV["DAVID"]
			recipient = { "id" => fb_id }
			register_user(recipient)
			expect(User.count).to eq 1
			user = User.first
			expect(user.fb_id).to eq fb_id
			expect(user.name).to eq "David McPeek"
			expect(user.child_name).to eq "Galen McPeek"
			expect(user.phone).to eq "8186897323"
			expect(user.id).to eq init.id
		end

		it "picks the first user who matches a child when there are many of such users" do 
			candidate0 = User.create
			candidate1 = User.create(:child_name => "Ben McPeek")
			candidate2 = User.create(:child_name => "Emily McPeek")
			fb_id = ENV["DAVID"]
			recipient = { "id" => fb_id }
			register_user(recipient)
			expect(User.count).to eq 3
			expect(User.where(:id => candidate1.id).first.name).to eq "David McPeek"
		end

		it "retains teacher info for parents" do
			teacher = Teacher.create
			User.create(:child_name => "Fun Town USA")
			init = User.create(:child_name => "Galen McPeek", :phone => "8186897323")
			teacher.add_user(init)
			fb_id = ENV["DAVID"]
			recipient = { "id" => fb_id }
			register_user(recipient)
			user = User.where(:fb_id => fb_id).first
			expect(user.teacher.id).to eq teacher.id
			expect(user.phone).to eq init.phone
		end

		it "creates a new user when there is no matching user for the child in the database" do
			some_user = User.create(:child_name => "Phil Esterman", :phone => "phil_phone") 
			fb_id = ENV["DAVID"]
			recipient = { "id" => fb_id }
			register_user(recipient)
			expect(User.count).to eq 2
			user = User.where(:fb_id => fb_id)
			expect(user.count).to eq 1
			user = user.first
			expect(user.fb_id).to eq fb_id
			expect(user.name).to eq "David McPeek"
			expect(user.child_name).to be_nil
			expect(user.phone).to be_nil
			expect(user.id).to_not eq some_user.id
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