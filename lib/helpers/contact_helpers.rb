<<<<<<< HEAD
require_relative '../../config/pony'

module ContactHelpers

  def send_sms( phone_no, text )
    HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/txt", 
      body: {
        recipient: phone_no,
        text: text
    })
  end

  def send_mms( phone_no, img_url )
    HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/mms", 
      body: {
        recipient: phone_no,
        img_url: img_url
    })
  end


  def email_admins(subject, body)
    Pony.mail(:to => 'phil.esterman@yale.edu',
              :cc => 'david.mcpeek@yale.edu',
              :from => 'david.mcpeek@yale.edu',
              :headers => { 'Content-Type' => 'text/html' },
              :subject => subject,
              :body => body)
  end
=======
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
>>>>>>> master

  
end
