require 'spec_helper'
# require_relative '../models/story'

describe "Models" do

	before(:each) do
		@u = User.create
	end

	context "users" do
		it "has an enrollment_queue upon creation" do
			@eq = @u.enrollment_queue
			expect(@eq).to_not be_nil
		end

		it "has a state_table upon creation" do 
			@st = @u.state_table
			expect(@st).to_not be_nil
		end

		it "destroys its enrollment_queue upon destruction" do
			@u.destroy
			expect(EnrollmentQueue.all).to be_empty
		end

		it "adds associated button_press_logs" do
			@u.add_button_press_log(ButtonPressLog.create)
			expect(@u.button_press_logs).to eq([ButtonPressLog.first])
		end

		it "destroys all associated button_press_logs upon destruction" do
			@u.add_button_press_log(ButtonPressLog.create)
			@u.destroy 
			expect(ButtonPressLog.all).to be_empty
		end
	end

	context "state_table" do
		it "has a user" do
			expect(@u.state_table.user_id).to_not be_nil
		end
	end

	context "curriculum version", version:true do
		it "equals the ENV['CURRICULUM_VERSION'] in .env" do
			expect(@u.curriculum_version).to eq ENV['CURRICULUM_VERSION'].to_i
			env = ENV['CURRICULUM_VERSION']
			ENV['CURRICULUM_VERSION'] = '10'
			user = User.create
			expect(user.curriculum_version).to eq ENV['CURRICULUM_VERSION'].to_i
			ENV['CURRICULUM_VERSION'] = env
		end

		it "is a number" do
			expect(@u.curriculum_version.class).to be Fixnum
		end

	end

	context "enrollment_queue" do
		before(:each) do
			@eq = @u.enrollment_queue
		end

		it "nullifies enrollment_queue_id from associated user upon destruction" do
			@eq.destroy
			expect(User.where(id: @u.id).first.enrollment_queue).to be_nil
		end
	end

	context "button_press_logs" do
		it "associates with a user" do
			bp = ButtonPressLog.create
			@u.add_button_press_log(bp)
			expect(bp.user).to eq(@u)
		end
	end


end