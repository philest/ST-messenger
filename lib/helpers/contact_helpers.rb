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

  
end
