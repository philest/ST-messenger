require 'spec_helper'
require 'helpers/contact_helpers'
include ContactHelpers

describe ContactHelpers do

	describe "notify_admins" do 
	  include EmailSpec::Helpers
	  include EmailSpec::Matchers


		before(:each) do 
		  # Stub the twilio message request
		   body = "{\"sid\": \"MM34d9bd740850416ba9f9b6d407797c5b\", \"date_created\": \"Thu, 21 Jul 2016 17:36:13 +0000\", \"date_updated\": \"Thu, 21 Jul 2016 17:36:13 +0000\", \"date_sent\": null, \"account_sid\": \"ACea17e0bba30660770f62b1e28e126944\", \"to\": \"+13013328953\", \"from\": \"+12032023505\", \"messaging_service_sid\": null, \"body\": \"Hi, this is Mx. McEsterWahl. I'll be texting Lil' Aub books with StoryTime!\\n\\nYou can start now if you have Facebook Messenger. Tap here and enter 'go':\\njoinstorytime.com/go\", \"status\": \"queued\", \"num_segments\": \"1\", \"num_media\": \"1\", \"direction\": \"outbound-api\", \"api_version\": \"2010-04-01\", \"price\": null, \"price_unit\": \"USD\", \"error_code\": null, \"error_message\": null, \"uri\": \"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM34d9bd740850416ba9f9b6d407797c5b.json\", \"subresource_uris\": {\"media\": \"/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages/MM34d9bd740850416ba9f9b6d407797c5b/Media.json\"}}"
	       stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/ACea17e0bba30660770f62b1e28e126944/Messages.json").
	         with(:body => {"Body"=>"Here's the body", "From"=>"+12032023505", "To"=>"+15612125831"},
	              :headers => {'Accept'=>'application/json', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic QUNlYTE3ZTBiYmEzMDY2MDc3MGY2MmIxZTI4ZTEyNjk0NDo3MTZlMDU0N2JiZDgyYzE3OWI5YWFlOGViZmVmMGU5NQ==', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'twilio-ruby/4.11.1 (ruby/x86_64-darwin14 2.2.3-p173)'}).
	         to_return(:status => 200, :body => body, :headers => {})
		end		     


		it "should email the admins" do
    		expect(Pony).to(receive(:mail).with( {:to=>"phil.esterman@yale.edu", :cc=>"david.mcpeek@yale.edu", :from=>"david.mcpeek@yale.edu", :subject=>"Here's the body", :body=>"Here's the subject", :headers=>{ 'Content-Type' => 'text/html' }}))
    		notify_admins("Here's the body", "Here's the subject")	      # 	}
		end
	end

end
