require 'twilio-ruby'

module ContactHelpers

	def notify_admins(subject, body)
		Pony.mail(:to => 'phil.esterman@yale.edu',
	            :cc => 'david.mcpeek@yale.edu',
	            :from => 'david.mcpeek@yale.edu',
	            :subject => subject,
	            :body => body)

		# Send us an SMS as well
	    @client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']
	    @client.account.messages.create(
	      :body => subject,
	      :to => "+15612125831",     
	      :from => "+12032023505"
	    )

	end

	
end
