require 'spec_helper'
# require './ENV_LOCAL' # if running locally


describe "User" do
	context "When creating new users" do

		before(:each) do
			@user = build(:user)
		end


		after(:all) do
			# rollback
		end

		it "has the right fields" do
			expect(@user.name).to eq("Fleem Flom")  
			expect(@user.phone).to eq("+18186897323") 
			expect(@user.fb_id).to eq("12345678")
		end

		it "has the correct default values" do
			expect(@user.story_number).to eq(0)
			expect(@user.language).to eq("English")
			expect(@user.send_time.hour).to eq 19
			expect(@user.send_time.min).to eq 0
		end
	end
end

