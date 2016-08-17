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

class SMS < Sinatra::Base
  include ContactHelpers

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
    user = User.where(phone: phone.to_s).first
    puts "user = #{user}, phone = #{phone}"

    if user # is enrolled in the system already
      teacher = (user.nil? or user.teacher.nil?) ? I18n.t('defaults.teacher') : user.teacher.signature
      session["teacher_reply"] ||= false
      case params[:Body]
      when /learn/i
        # run help message
        msg = I18n.t 'user_response.learn'
      else
        if session["teacher_reply"]
          msg = I18n.t 'user_response.teacher_reply.session'

        else
          msg = I18n.t 'user_response.teacher_reply.no_session'
          session["teacher_reply"] = true 
        end
      end

      puts "msg to send = #{msg}"

      # send that message back! 
      send_sms( phone, msg )


      if user.child_name
        name = user.child_name
      elsif user.first_name and user.last_name
        name = user.first_name + " " + user.last_name
      else
        name = "A user"
      end

      email_admins "#{name} - #{phone} texted StoryTime", \
             "Message: #{params[:Body]}<br/>Time: #{Time.now}"


    else # this is a new user, enroll them in the system 

      puts "someone texted in, creating user..."

      new_user = User.create(phone: phone, platform: 'sms')


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
      MessageWorker.perform_async(phone, script_name='day1', sequence='firstmessage', platform='sms')


      our_phones = ["5612125831", "8186897323", "3013328953"]
      is_us = our_phones.include? phone 

      if !is_us 
        email_admins "A new user with phone #{phone} has enrolled by texting in", \
               "Phone: #{phone}<br/>Message:#{params[:Body]}<br/>School: #{school_signature}"
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
        if parent.nil?   then parent = User.create(:phone => phone_num, platform: 'sms')      end

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
    MessageWorker.perform_async('8186897323', script_name='day2', sequence='firstmessage', platform='sms')
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


    if status == 'delivered' and next_sequence.to_s != '' # if it's not an empty sequence dawg....
      MessageWorker.perform_async(phone, script_name=script, sequence=next_sequence, platform='sms') 
    elsif next_sequence.to_s == ''
      puts "no more sequences, we're all done with this script :)"
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



end # class SMS < Sinatra::Base








