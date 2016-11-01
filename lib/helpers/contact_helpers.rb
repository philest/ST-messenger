require_relative '../../config/pony'
require 'httparty'
require_relative 'twilio_helpers'

module ContactHelpers

  def email_admins(subject, body)
    Pony.mail(:to => 'phil.esterman@yale.edu,supermcpeek@gmail.com',
              :cc => 'aawahl@gmail.com',
              :from => 'david.mcpeek@yale.edu',
              :headers => { 'Content-Type' => 'text/html' },
              :subject => subject,
              :body => body)
  end

	def notify_admins(subject, body)
    email_admins(subject, body)
    text_body   = subject + ":\n" + body
    david, phil = '+18186897323', '+15612125831'
    if text_body.length < 360
      TextingWorker.perform_async(text_body, david, ENV['ST_USER_REPLIES_NO'])
      TextingWorker.perform_async(text_body, phil, ENV['ST_USER_REPLIES_NO'])
    else
      TextingWorker.perform_async(subject, david, ENV['ST_USER_REPLIES_NO'])
      TextingWorker.perform_async(subject, phil, ENV['ST_USER_REPLIES_NO'])

    end
	end
  
end
