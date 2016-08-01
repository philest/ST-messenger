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
 
  get '/sms' do
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

      puts "someone texted in, creatin`g user..."

      new_user = User.create(phone: phone)


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

  post '/enroll' do
    "yo, we're at /enroll now!"
  end

  post '/' do
    "yo, we're at / now!"
  end




end # class SMS < Sinatra::Base









