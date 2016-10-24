#  app.rb                                     David McPeek      
# 
#  The routes controller. Recieves POST from 
#  www.joinstorytime.com/enroll with family phones and names. 
#  --------------------------------------------------------

#sinatra dependencies 
require 'sinatra/base'
require 'sidekiq'
require 'sidekiq/web'
require 'twilio-ruby'
# require_relative '../config/environment'
require 'pony'
require 'dotenv'
Dotenv.load if ENV['RACK_ENV'] != 'production'
require_relative '../config/pony'
require_relative 'workers'
require 'httparty'
require_relative 'helpers/contact_helpers' 
require_relative 'helpers/reply_helpers'
require_relative 'helpers/twilio_helpers'
require_relative 'helpers/name_codes'
require_relative 'helpers/generate_phone_image'
require_relative 'bot/dsl'
require_relative 'bot/sms_dsl'
require_relative '../config/initializers/airbrake'
require_relative '../config/initializers/redis'


class TextApi < Sinatra::Base
  include ContactHelpers
  include MessageReplyHelpers
  include TwilioTextingHelpers
  include NameCodes

  use Airbrake::Rack::Middleware

  set :session_secret, "328479283uf923fu8932fu923uf9832f23f232"
  enable :sessions

  set :root, File.join(File.dirname(__FILE__), '../')

  get '/' do
    params[:kingdom] ||= "Angels"
    "Bring me to the Kingdom of #{params[:kingdom]}"
  end


  post '/signup' do
    # create teacher here
    email       = params[:email]
    signature   = params[:signature]
    password    = params[:password]

    puts "params = #{params}"

    if !email or !signature or !password
      return "invalid data. need email, signature, and password"
    end

    password_regexp = Regexp.new("#{password}\\|.+", 'i')
    
    # note: when we give out passwords, we just do the english version of a school
    school = School.where(Sequel.like(:code, password_regexp)).first
    if school.nil?
      return "incorrect password"
    end

    # maybe have some way to increment teacher codes for schools? 

    teacher = Teacher.where(email: email).first
    if teacher.nil?
      teacher = Teacher.create(email: email, signature: signature)
    end

    # this will automatically create a teacher code
    school.signup_teacher(teacher)

    teacher.reload
    image = PhoneImage.create_image(teacher.code.split('|').first.upcase)

    return {
      teacher: teacher,
      school: school,
      secret: 'our little secret'
    }.to_json
  end

  get '/enroll-forms/:code' do
    send_file File.join(settings.public_folder, 
                            "enroll-phone/#{params[:code]}-enroll.png")
  end

  get '/delivery_status' do
    begin 
      messageSid    = params['messageSid']
      client        = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']
      message       = client.account.messages.get( messageSid )
      status        = message.status
      return status
    rescue => e
      p "MessageSID: #{messageSid} - " + e.message
      email_admins("st-enroll: something went wrong with MessageSID: #{messageSid}", e.message)
    end
  end

  post '/sms' do
    content_type 'text/xml'
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
      
      reply = ''
      if (msg == (I18n.t 'user_response.default')) && session['end_conversation'] == true
        # do nothing, don't send message
        reply = ''
        puts "should not send a message reply until session expires.........."
      elsif (msg == (I18n.t 'user_response.default')) && session['end_conversation'] != true
        session['end_conversation'] = true
        reply = name_codes(msg, user)
        puts "reply to send (end_conversation is now true) = #{reply}"
      else
        reply = name_codes(msg, user)
        puts "reply to send = #{reply}"
      end
      
      unless reply.nil? or reply.empty? or reply.downcase.include? 'translation missing'
        TextingWorker.perform_async(reply, phone)

        #
        # conditional reply logic below
        #
        if reply == (I18n.t 'scripts.enrollment.sms_optin.teacher') or
           reply == (I18n.t 'scripts.enrollment.sms_optin.school') or
           reply == (I18n.t 'scripts.enrollment.sms_optin.none')
          MessageWorker.perform_async(phone, 'day2', 'image1', 'sms')
        end
        # handle english/spanish conversation
        if (reply == "Got it! We'll send you English stories instead.") or
           (reply == "Bien! Le enviaremos cuentos en español :)")

           # only do this for the first text... 
           # otherwise, just change their locale and keep according to the SCRIPT!!!
           if user.state_table.story_number == 1
              call_to_action = name_codes(I18n.t('scripts.enrollment.call_to_action'), user)
              TextingWorker.perform_in(5.seconds, call_to_action, phone)
            end
        end
        #
        # end conditional reply logic below
        #
      else # there was no reply, so we want to personally respond to this. 
        REDIS.set('last_textin', phone) # remember the last person who texted in

        if reply.include? 'translation missing'
          notify_admins(reply, '')
        end

      end

      our_phones = ["5612125831", "8186897323", "3013328953"]
      is_us = our_phones.include? phone


      if !is_us 
        notify_admins "#{phone} texted StoryTime", "Msg: \"#{params[:Body]}\""
        unless reply.nil? or reply.empty?
          reply_blurb = reply[0..60]
          notify_admins "#{phone} texted StoryTime", \
              "we responded with \"#{reply_blurb}#{'...' if reply.length > 60}\""
        end
      end

      # a necessary tag... must always respond with TwiML
      "<Response/>"
          
    else # this is a new user, enroll them in the system 

      puts "someone texted in, creating user..."

      new_user = User.create(phone: phone, platform: 'sms')
      # user start out as unsubscribed and needs to opt-in to SMS
      new_user.state_table.update(subscribed?: false)
      # story_number needs to start at 0 for texting
      # new_user.state_table.update(story_number: 0)

      # if the first text has "spanish" or "español" in it...
      spanish_regex = /(spanish)|(espa[ñn]ol)/i
      if spanish_regex.match params[:Body]
        new_user.update(locale: 'es')
      end
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
        if code.nil?
          next
        end
        code.downcase!
        body_text = params[:Body].delete(' ').downcase

        if code.include? body_text
          en, sp = code.split('|')
          if body_text == en
            I18n.locale = 'en'
            puts "school info: #{school.signature}, #{school.inspect}"
            school.add_user(new_user)
          elsif body_text == sp
            I18n.locale = 'es'
            new_user.update(locale: 'es')
            puts "school info: #{school.signature}, #{school.inspect}"
            school.add_user(new_user)
          else 
            puts "#{code} did not match with #{school.name} regex!"
          end
        end
      end

      # DO THE SAME FOR TEACHERS HERE?
      # not only connect them with a teacher, but connect them to that teacher's school
      Teacher.each do |teacher|
        code = teacher.code
        if code.nil?
          next
        end
        code.downcase!
        body_text = params[:Body].delete(' ').downcase

        if code.include? body_text
          en, sp = code.split('|')
          if body_text == en
            I18n.locale = 'en'
            puts "teacher info: #{teacher.signature}, #{teacher.inspect}"
            teacher.add_user(new_user)
            if !teacher.school.nil? # if this teacher belongs to a school
              teacher.school.add_user(new_user)
            end

          elsif body_text == sp
            I18n.locale = 'es'
            new_user.update(locale: 'es')
            puts "teacher info: #{teacher.signature}, #{teacher.inspect}"
            teacher.add_user(new_user)
            if !teacher.school.nil? # if this teacher belongs to a school
              teacher.school.add_user(new_user)
            end

          else 
            puts "#{code} did not match with #{teacher.name} regex!"
          end
        end # if code.include? body_text
      end # Teacher.each do |teacher|

      # perform the day1 mms sequence
      StartDayWorker.perform_async(phone, platform='sms')

      # let us know
        our_phones = ["5612125831", "8186897323", "3013328953"]
        is_us = our_phones.include? phone 

        if !is_us 
          notify_admins "A new user #{phone} has enrolled by texting in", \
                 "Code: \"#{params[:Body]}\""
        end
      # end let us know

      # a necessary tag... must always respond with TwiML
      "<Response/>"

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

        # create new parent if didn't already exists
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

        if !teacher.school.nil? # if this teacher belongs to a school
          teacher.school.add_user(parent)
        end
      
      rescue Sequel::Error => e
        puts e.message
        # TODO: send email to Phil...
      end     
    end

    # success even if twilio stuff not work 'cos
    # twilio happens in a separate process :)
    status 201
  end


  post '/reply' do
    # get the first string in the message
    # check to see if user exists with that number
    # if they do, send the rest of the text to them
    # 
    body = params[:Body]
    regex = / \s* reply \s* (\d+) \s* $/ix
    if regex.match body
      phone = $1.to_s
      # process format
      phone.gsub!(/[-()\s]/, '')
      puts "phone is #{phone}"
      # check database
      user = User.where(phone: phone).first
      if user
        # get the message to sending
        message = body.lines[1..-1].join
        TextingWorker.perform_async(message, phone, ENV['ST_MAIN_NO'])

        phil, david = ["5612125831", "8186897323"]
        from = params[:From][2..-1]
        case from
        when phil
          puts "send message to david"
          phil_reply = "Phil just replied to #{phone}. He wrote: \"#{message}\""
          TextingWorker.perform_async(phil_reply, david, ENV['ST_USER_REPLIES_NO'])
        when david
          puts "send message to phil"
          david_reply = "José David just replied to #{phone}. He wrote: \"#{message}\""
          TextingWorker.perform_async(david_reply, phil, ENV['ST_USER_REPLIES_NO'])
        end
      else
        puts "no user was found that matches #{phone}"
        404
      end # if user
    elsif (phone = REDIS.get('last_textin')) # if no match, send to the last person who texted in
      REDIS.del('last_textin')
      user = User.where(phone: phone).first
      if user
        message = body
        TextingWorker.perform_async(message, phone, ENV['ST_MAIN_NO'])
        phil, david = ["5612125831", "8186897323"]
        from = params[:From][2..-1]
        case from
        when phil
          puts "send message to david"
          phil_reply = "Phil just replied to #{phone}. He wrote: \"#{message}\""
          TextingWorker.perform_async(phil_reply, david, ENV['ST_USER_REPLIES_NO'])
        when david
          puts "send message to phil"
          david_reply = "José David just replied to #{phone}. He wrote: \"#{message}\""
          TextingWorker.perform_async(david_reply, phil, ENV['ST_USER_REPLIES_NO'])
        end
      else
        print "no user was found that matches #{phone}... "
        puts "odd, because this is the same phone that once texted in"
        404
      end # if user
    else # if no REDIS 'last_textin' key exists
      puts "no one to text back to...."
      no_send_reply = "Message didn't send, someone may have already replied."
      TextingWorker.perform_async(no_send_reply, params[:From], ENV['ST_USER_REPLIES_NO'])
    end # if regex.match body

    # a necessary tag... must always respond with TwiML
    "<Response/>"
  end # post '/reply'

  get '/test' do
    day = params['day']
    if day
      MessageWorker.perform_async('8186897323', script_name="day#{day}", sequence='firstmessage', platform='sms')
    else
      MessageWorker.perform_async('8186897323', script_name='day1', sequence='firstmessage', platform='sms')
    end
  end

  get '/startdayworker' do
    if params[:recipient] and params[:platform]
      StartDayWorker.perform_async(params[:recipient], params[:platform])
      'ass'
    else
      User.each do |u|
        case u.platform
        when 'fb'
          StartDayWorker.perform_async(u.fb_id, 'fb')
        when 'sms', 'feature'
          StartDayWorker.perform_async(u.phone, u.platform)
        end
      end
      'hole'
    end
  end

  get '/scheduleworker' do
    ScheduleWorker.perform_async()
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
    last_sequence = params['last_sequence']
    messageSid    = params['MessageSid']
    puts "script: #{script}"
    puts "next_sequence: #{next_sequence}"
    puts "last_sequence: #{last_sequence}"

    status = params['MessageStatus']
    puts "status: #{status}"

    # or maybe the clock worker happens here...
    if status == 'delivered' then # we've completed a sequence, so record its history
      u = User.where(phone: phone).first

      if u.nil? 
        return 400
      end

      b = ButtonPressLog.new(script_name:script, 
                             sequence_name:last_sequence, 
                             platform: u.platform)
      u.add_button_press_log(b) unless u.nil? 
      puts "b.user = #{b.user.inspect}"
    end

    if status == 'delivered' and next_sequence.to_s != '' # if it's not an empty sequence dawg....
      user = User.where(phone: phone).first

      if user.nil?
        return 400
      end

      user_buttons = ButtonPressLog.where(user_id:user.id)
      # if next_sequence == nil, then they've probably already seen a sequence like nil
      we_have_a_history = !user_buttons.where(platform:user.platform,
                                             script_name:script, 
                                             sequence_name:next_sequence).first.nil?
      if we_have_a_history
        puts "app.rb - WE'VE ALREADY SEEN #{script.upcase} #{next_sequence.upcase}!!!!"
      else
        MessageWorker.perform_async(phone, script_name=script, sequence=next_sequence, platform=user.platform) 
      end

    elsif next_sequence.to_s == ''
      puts "no more sequences, we're all done with this script :)"
    elsif status == 'sent' # it's been over a minute since we've received the last message and we're not waiting anymore...
      # should TimerWorker perform the next_sequence, or the last_sequence? Oh God!!!!!
      TimerWorker.perform_in(45.seconds, messageSid, phone, script_name=script, next_sequence=next_sequence)

    elsif status == 'failed'
      # do something else
      puts "message failed to send."
    end

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









