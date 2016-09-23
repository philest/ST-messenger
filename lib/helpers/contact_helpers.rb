require_relative '../../config/pony'

module ContactHelpers

  def sms( phone_no, text, sender=ENV['ST_MAIN_NO'] )
    HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/txt", 
      body: {
        recipient: phone_no,
        text: text,
        sender: sender
    })
  end

  def mms( phone_no, img_url, sender=ENV['ST_MAIN_NO'] )
    HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/mms", 
      body: {
        recipient: phone_no,
        img_url: img_url,
        sender: sender
    })
  end

  def email_admins(subject, body)
    Pony.mail(:to => 'phil.esterman@yale.edu',
              :cc => 'aawahl@gmail.com',
              :from => 'davidmcpeek1@gmail.com',
              :headers => { 'Content-Type' => 'text/html' },
              :subject => subject,
              :body => body)
  end

	def notify_admins(subject, body)
    text_body   = "#{subject}\nMsg: \"#{body}\""
    email_admins(subject, body)
    if text_body.length < 360
      sms('+18186897323', text_body, ENV['ST_USER_REPLIES_NO']) # david
      sms('+15612125831', text_body, ENV['ST_USER_REPLIES_NO']) # phil
    end
	end
  
end
