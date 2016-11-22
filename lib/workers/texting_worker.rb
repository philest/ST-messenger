require_relative '../helpers/twilio_helpers'
require_relative '../helpers/contact_helpers'

class TextingWorker 
  include Sidekiq::Worker
  include TwilioTextingHelpers
  include ContactHelpers

  sidekiq_options :retry => 2
  
  sidekiq_retries_exhausted do
    email_admins("ST: Failed to send message",'')
    Sidekiq.logger.warn "Failed to send message for some reason :( "
  end

  sidekiq_retry_in do |count|
    10 * (count + 1) # (i.e. 10, 20, 30, 40)
  end

  # hashes passed in sidekiq workers could be bad

  def perform (msg, to_phone, from_phone=ENV['ST_MAIN_NO'], type=SMS, next_sequence={}) 
    if type == MMS 
      # send MMS to user
      begin
        mms(msg, to_phone, from_phone, next_sequence)
        
      rescue Twilio::REST::RequestError => e
        puts "we've encountered a Twilio error."
        # TODO: describe the ramifications
        email_admins("Twilio Error", "Status: #{Time.now.to_s}\nFailed MMS send, #{e.inspect}, \nphone_number: #{to_phone}.")
        Sidekiq.logger.warn e
      end
    else # SMS 
      begin
        sms(msg, to_phone, from_phone, next_sequence)
        
      rescue Twilio::REST::RequestError => e
        puts "we've encountered a Twilio error."
        # TODO: describe the ramifications
        email_admins("Twilio Error", "Status: #{Time.now.to_s}\nFailed SMS send, #{e.inspect}, \nphone_number: #{to_phone}.")
        Sidekiq.logger.warn e
      end
    end
  end
end