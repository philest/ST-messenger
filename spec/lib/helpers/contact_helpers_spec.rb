require 'spec_helper'
require 'helpers/contact_helpers'
include ContactHelpers

describe ContactHelpers do

	describe "email_admins" do 
	  include EmailSpec::Helpers
	  include EmailSpec::Matchers

		it "should email the admins" do
    		expect(Pony).to(receive(:mail).with( {:to=>"phil.esterman@yale.edu", :cc=>"david.mcpeek@yale.edu", :from=>"david.mcpeek@yale.edu", :subject=>"Here's the body", :body=>"Here's the subject", :headers=>{ 'Content-Type' => 'text/html' }}))
    		email_admins("Here's the body", "Here's the subject")	      # 	}
		end
	end

end
