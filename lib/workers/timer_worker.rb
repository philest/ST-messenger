require 'httparty'
# if an SMS hasn't been delivered within twenty seconds or so, send the next_sequence
class TimerWorker
  include Sidekiq::Worker

  def perform(messageSid, phone, script_name, next_sequence)

    res = HTTParty.get("#{ENV['ST_ENROLL_WEBHOOK']}/delivery_status?messageSid=#{messageSid}")

    if res.code == 200
      status = res.response.body

      case status
      when 'delivered'
        puts "Our message #{messageSid} has been delivered, we don't need to do anything more about it."
        return
      when 'failed'
        puts "Our poor message #{messageSid} has failed to send. I'm very sorry."
        return
      when 'sent'
        puts "This motherfucker is still at 'sent'! WTF?? We're just gonna send the next one... fuck."
        MessageWorker.perform_async(phone, script_name, next_sequence, platform='sms')
      end

    else
      puts "http://st-enroll.herokuapp.com/delivery_status failed with status #{res.code}"
      return
    end

  end

end