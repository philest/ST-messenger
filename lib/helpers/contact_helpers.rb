require_relative '../../config/pony'
require 'httparty'
require_relative 'twilio_helpers'

module ContactHelpers

  def email_admins(subject, body = "[blank]")
    Pony.mail(:to => 'phil.esterman@yale.edu',
              :cc => 'aawahl@gmail.com',
              :from => 'phil@joinstorytime.com',
              :headers => { 'Content-Type' => 'text/html' },
              :subject => subject,
              :body => body)
  end

	def notify_admins(subject, body = "[blank]")
    email_admins(subject, body)
    text_body   = subject + ":\n" + body
    phil, aubs = '+15612125831', '+13013328953'
    if text_body.length < 360
      TextingWorker.perform_async(text_body, phil, ENV['ST_USER_REPLIES_NO'])
      TextingWorker.perform_async(text_body, aubs, ENV['ST_USER_REPLIES_NO'])
    else
      TextingWorker.perform_async(subject, phil, ENV['ST_USER_REPLIES_NO'])
      TextingWorker.perform_async(subject, aubs, ENV['ST_USER_REPLIES_NO'])
    end
	end
end
