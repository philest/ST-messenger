#  app.rb                                     David McPeek      
# 
#  The routes controller. Recieves POST from 
#  www.joinstorytime.com/enroll with family phones and names. 
#  --------------------------------------------------------

#sinatra dependencies 
require 'sinatra/base'
require 'sidekiq'
require 'sidekiq/web'
require_relative '../config/environment'
require 'pony'
require 'dotenv'
Dotenv.load if ENV['RACK_ENV'] != 'production'
require_relative '../config/pony'
require_relative 'workers'
require 'httparty'
require_relative 'helpers/contact_helpers' 
require_relative 'helpers/reply_helpers'
require_relative 'bot/sms_dsl'

class SMS < Sinatra::Base
  include ContactHelpers
  include MessageReplyHelpers

  enable :sessions

  get '/' do
    params[:kingdom] ||= "Angels"
    "Bring me to the Kingdom of #{params[:kingdom]}"
  end
 
  post '/sms' do
    # begin
    # check if user is enrolled in the system
    if params[:From].nil?
      return 404
    end
    phone = params[:From][2..-1]
    puts "params[:From] = #{params[:From]}"
    puts "params[:Body] = #{params[:Body]}"
    user = User.where(phone: phone.to_s).first
    puts "user = #{user}, phone = #{phone}"

    if user # is enrolled in the system already

      msg = get_reply(params[:Body], user)

      puts "session = #{session.inspect}"
      
      if (msg == (I18n.t 'user_response.default')) && session['end_conversation'] == true
        # do nothing, don't send message
        puts "should not send a message reply until session expires.........."
      elsif (msg == (I18n.t 'user_response.default')) && session['end_conversation'] != true
        session['end_conversation'] = true
        reply = SMSReplies.name_codes(msg, user)
        puts "reply to send (end_conversation is now true) = #{reply}"
        sms(phone, reply)
      else
        reply = SMSReplies.name_codes(msg, user)
        puts "reply to send = #{reply}"
        sms(phone, reply)
      end

      our_phones = ["5612125831", "8186897323", "3013328953"]
      is_us = our_phones.include? phone 

      if !is_us 
        notify_admins "A user (phone #{phone}) texted StoryTime", \
             "Message: #{params[:Body]}<br/>Time: #{Time.now}"
      end
          
    else # this is a new user, enroll them in the system 

      puts "someone texted in, creating user..."

      new_user = User.create(phone: phone, platform: 'sms')
      # user start out as unsubscribed and needs to opt-in to SMS
      new_user.state_table.update(subscribed?: false)
      # story_number needs to start at 0 for texting
      # new_user.state_table.update(story_number: 0)

      # TODO: error handling, nil-value checking
      # 
      # FORMAT FOR SCHOOL CODES:
      # "english_word|spanish_word"
      # Example: 'read1|leer1'
      # 
      # 1. All lower-case
      # 2. English first, then Spanish
      # 3. separated by pipe
      #  
      School.each do |school|
        code = school.code
        code_regex = Regexp.new(code, "i")
        body_text = params[:Body].delete(' ')
        match_data = code_regex.match body_text
        puts "match data = #{match_data.inspect}"

        if match_data then # we've matched this school
          match_data = match_data.to_s.downcase
          # codes should be split like this: "read1|leer1"
          en, sp = code.split('|')
          # check which language they're going for
          if match_data == en
            I18n.locale = 'en'
          elsif match_data == sp
            I18n.locale = 'es'
            new_user.update(locale: 'es')
          end

          puts "school info: #{school.signature}, #{school}"

          school.add_user(new_user)
          puts "school's users = #{school.users.to_s}"
          puts "user's school = #{new_user.school.inspect}"
        end
      end

      # TODO: make sure locale settings are consistent.
      #       they must also reset to english and not leak between jobs.

      # perform the day1 mms sequence
      StartDayWorker.perform_async(phone, platform='sms')


      our_phones = ["5612125831", "8186897323", "3013328953"]
      is_us = our_phones.include? phone 

      if !is_us 
        email_admins "A new user with phone #{phone} has enrolled by texting in", \
               "Phone: #{phone}<br/>Message:#{params[:Body]}"
      end
    end
  end


  post '/' do
    puts "enrolling parents..."


    signature = params["teacher_signature"]
    temail    = params["teacher_email"]

    begin
      teacher = Teacher.create(:signature => signature, email: params['teacher_email'])
      puts "created new teacher: #{signature}"
    rescue Sequel::Error => e
      p e.message + " didn't insert teacher, her email already exists in db"
      # TODO: return to user that the thing failed if couldn't insert, ask
      #       to try submitting again
      teacher = Teacher.where(email: params['teacher_email']).first
    end

    # Create the parents
    25.times do |idx| # TODO: this loop is shit
      
      if params["phone_#{idx}"] != nil
        phone_num   = params["phone_#{idx}"]
        child_name  = params["name_#{idx}"]
      else 
        # email Phil
        next      
      end

      # TODO some day: when insertion fails, let teacher know that parent already exists
      # and that if they click confirm, they may be changing the kid's number (make this
      # happen in seperate worker?)
      begin
        # I sure hope the phone number made it in!
        parent = User.where(phone: phone_num).first

        # create new parent if did'nt already exists
        if parent.nil? then 
          parent = User.create(:phone => phone_num, platform: 'sms')
          parent.state_table.update(subscribed?: false)
          # parent.state_table.update(story_number: 0)
        end

        # update parent's student name
        if not child_name.nil? then parent.update(:child_name => child_name) end

        # add parent to teacher!
        teacher.add_user(parent)
        puts "added #{parent.child_name if not params["name_#{idx}"].nil?}, phone => #{parent.phone}"
      
      rescue Sequel::Error => e
        puts e.message
        # TODO: send email to Phil...
      end     
    end

    # success even if twilio stuff not work 'cos
    # twilio happens in a seperate process :)
    status 201
  end

  get '/test' do
    day = params['day']
    if day
      MessageWorker.perform_async('8186897323', script_name="day#{day}", sequence='firstmessage', platform='sms')
    else
      MessageWorker.perform_async('8186897323', script_name='day1', sequence='firstmessage', platform='sms')
    end
  end

  get '/run_sequence' do
    script = params['script']
    sequence = params['sequence']
    platform = params['platform']
    recipient = params['recipient']

    if recipient.nil? 
      if platform == 'fb'
        recipient = "1042751019139427"
      else
        recipient = "8186897323"
      end
    end

    puts script, sequence, platform, recipient

    MessageWorker.perform_async(recipient, script, sequence, platform)
  end


  post '/twilio_callback_url' do

    puts "IN THE BIRDV TWILIO CALLBACK URL YAY BIRDV!!!"
    puts params.inspect

    phone         = params['phone']
    script        = params['script']
    next_sequence = params['next_sequence'] 
    messageSid    = params['MessageSid']
    puts "script: #{script}"
    puts "next_sequence: #{next_sequence}"

    status = params['MessageStatus']
    puts "status: #{status}"

    # or maybe the clock worker happens here...


    if status == 'delivered' and next_sequence.to_s != '' # if it's not an empty sequence dawg....
      MessageWorker.perform_async(phone, script_name=script, sequence=next_sequence, platform='sms') 
    elsif next_sequence.to_s == ''
      puts "no more sequences, we're all done with this script :)"
    elsif status == 'sent' # it's been over a minute since we've received the last message and we're not waiting anymore...
      TimerWorker.perform_in(45.seconds, messageSid, phone, script_name=script, next_sequence=next_sequence)
      # maybe we just 
      # just send the message
      # this requires that we include the last_time_received as a url query param
      # so when do we do that? let's find out, shall we?
      # 
      # problem: we don't want the message that is still waiting to be delivered 
      # to fucking be delivered. then we'd get two of the same fucking texts. 
      # I need to figure out a way to cancel SMS in transit. 

      # The sequence of events
      # 1: 
      #   We send sms1. st-enroll schedules send_sms with script and next_sequence arguments.
      #   send_sms creates a Twilio message with a callback URL to birdv
      # 2: 
      #   birdv receives a POST to its callback url with parameters.
      #   status = 'sent'
      # 3:
      #   birdv waits. and waits. and waits. 
      # 4:
      #   someone decides that enough is enough and to send sms2. fair is fair.
    elsif status == 'failed'
      # do something else
      puts "message failed to send."
    end

    # # have some params like:
    # #   params[:sequence_name]
    # #   params[:script_name]
    # #   params[:recipient] 

    # # use MessageSID from the callback to lookup the phone number that the message was sent to.
    # # i.e. 8186897323
    # # then lookup that phone number from the database to check what the last_sequence_seen was
    # # for that user
    # #   meaning that somewhere, maybe in the dsl or scripts, we have to update a user's last_sequence_seen column
    # #
    # # 
    # # we need some way of telling the next sequence from last_sequence_seen, but the point is, from the last sequence
    # # that a user saw which we can record on the birdv side, we can figure out what next to send them. 

    # messageSID = params[:MessageSid]

    # # do GET to twilio api to get the fucking message. Then lookup the phone number. This may have to
    # # be done on the st-enroll side because it's using the Twilio api, fuck it. 
    # # If it's done on the twilio side, just have that POST to fucking birdv with the phone number and status info
    # phone = params[:phone]

    # user = User.where(phone: phone)

    # next_sequence = user.state_table.next_sequence
    # # somehow get the user's script_day, should be easy 

  end


    # send the demo
  post '/demo' do
    phone = params[:phone]
    puts "sending demo to #{phone}"
    MessageWorker.perform_async(phone, script_name='demo', sequence='firstmessage', platform='demo')
  end 

  post '/demo/sms' do
    # msg = "Hi! We're away now, but we'll see your messsage soon. "+
    # "To learn more about StoryTime, call 561-212-5831."
    msg = I18n.t 'demo.response'

    twiml = Twilio::TwiML::Response.new do |r|
      # r.Message "StoryTime: Hi, we'll send your text to #{user.teacher.signature}. They'll see it next time they are on their computer."
      r.Message msg
    end
    twiml.text
  end




end # class SMS < Sinatra::Base









