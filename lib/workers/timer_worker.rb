require 'httparty'
# if an SMS hasn't been delivered within twenty seconds or so, send the next_sequence
class TimerWorker
  include Sidekiq::Worker

  def delivery_status(messageSid)
    begin 
      client        = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']
      message       = client.account.messages.get( messageSid )
      status        = message.status
      return status
    rescue => e
      p "MessageSID: #{messageSid} - " + e.message
      email_admins("st-enroll: something went wrong with MessageSID: #{messageSid}", e.message)
    end
  end


  def perform(messageSid, phone, script_name, next_sequence)
    puts "******************************************"
    puts "WE'RE IN THE TIMERWORKER BITCHES!!!!!\n\n"
    puts "script_name = #{script_name}"
    puts "next_sequence = #{next_sequence}"
    puts "******************************************"

    # res = HTTParty.get("#{ENV['ST_ENROLL_WEBHOOK']}/delivery_status?messageSid=#{messageSid}")
    status = delivery_status(messageSid)
    puts "delivery_status = #{status.inspect}"
    
    case status
    when 'delivered'
      puts "Our message #{messageSid} has been delivered, we don't need to do anything more about it."
      return
    when 'failed'
      puts "Our poor message #{messageSid} has failed to send. I'm very sorry."
      return
    when 'sent'
      puts "This motherfucker is still at 'sent'! WTF?? We're just gonna send the next one... fuck."
      user = User.where(phone: phone).first
      
      if user.nil?
        return 400
      end

      user_buttons = ButtonPressLog.where(user_id:user.id)
      we_have_a_history = !user_buttons.where(platform:user.platform,
                                             script_name:script_name, 
                                             sequence_name:next_sequence).first.nil?
      if we_have_a_history
        puts "timer_worker.rb - WE'VE ALREADY SEEN #{script_name.upcase} #{next_sequence.upcase}!!!!"
      else
        MessageWorker.perform_async(phone, script_name, next_sequence, platform=user.platform)
      end

    end

  end

end