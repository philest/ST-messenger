module TwilioTextingHelpers
	# our twilio number
	STORYTIME_NO 	= "+12032023505"
	# Sprint name, from Twilio_Lookups url. 
	SPRINT = "Sprint Spectrum, L.P."
	ATT = "AT&T Wireless"
	# Sleep to have two SMS deliver in order
	SMS_SLEEP = 8

	# Wrappers for Twilio calls.
	def send_sms(body, phone)
		client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']
		client.account.messages.create(
		  :body => body,
		  :to => phone,     
		  :from => STORYTIME_NO
		)

		puts "Sent SMS to #{phone}."  
	end

	def send_mms(media_url, phone)
		client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']
		client.account.messages.create(
		  :media_url => media_url,
		  :to => phone,     
		  :from => STORYTIME_NO
		)

		puts "Sent MMS to #{phone}."     
	end

	def get_carrier(phone)
		# Get the user's phone carrier. 
		@lookups_client = Twilio::REST::LookupsClient.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
		twilio_lookup = @lookups_client.phone_numbers.get(phone, type: 'carrier')
		carrier = twilio_lookup.carrier['name']
		return carrier
	end

	def email_admins(subject, body)
		Pony.mail(:to => 'phil.esterman@yale.edu',
	            :cc => 'david.mcpeek@yale.edu',
	            :from => 'david.mcpeek@yale.edu',
	            :subject => subject,
	            :body => body)
	end

	# Does the carrier need 160-char segments? 
	def good_carrier?(carrier)
		if carrier != SPRINT &&
			carrier != ATT
			return true
		else 
			return false
		end 
	end
	
end
