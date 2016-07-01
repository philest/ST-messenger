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