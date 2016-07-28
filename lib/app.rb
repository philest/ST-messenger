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

      # rescue  
      # end

      if user.child_name
        name = user.child_name
      elsif user.first_name and user.last_name
        name = user.first_name + " " + user.last_name
      else
        name = "A user"
      end

      # send HTTP request to send text here?

      email_admins "#{name} - #{phone} texted StoryTime", \
             "Message: #{params[:Body]}<br/>Time: #{Time.now}"


      # twiml = Twilio::TwiML::Response.new do |r|
      #   # r.Message "StoryTime: Hi, we'll send your text to #{user.teacher.signature}. They'll see it next time they are on their computer."
      #   r.Message msg
      # end
      # twiml.text


    else # this is a new user, enroll them in the system 
      puts "someone texted in, creating user..."

      new_user = User.create(phone: phone, platform: 'mms')

      # TODO: process the body text (regex)
      code_regex = /(read|leer)\s*(\d+)/i

      match_data = code_regex.match params[:Body]

      puts "match data = #{match_data.inspect}"
      lang = $1
      code = $2

      puts "$1, $2 = #{lang}, #{code}"

      # TODO: make sure locale settings are consistent.
      #       they must also reset to english and not leak between jobs.

      # default vals
      school_signature = nil
      teacher = nil     

      # if we've matched with a proper code
      if lang and code
        case lang
        when /read/i
          puts "detected english from #{$1}"
          I18n.locale = 'en'
        when /leer/i
          puts "detected spanish from #{$1}"
          I18n.locale = 'es'
        end

        code = code.to_i
        puts "code = #{code}"
        # let's just index by school id for now... we'll develop a better system later. 
        school = School.where(id: code).first

        if school
          school_signature = school.signature
          puts "school info: #{school_signature}, #{school}"

          school.add_user(new_user)
          puts "school's users = #{school.users.to_s}"
          puts "user's school = #{new_user.school.inspect}"
        end

      end

      queue_id = new_user.enrollment_queue.nil? ? nil : new_user.enrollment_queue.id

      # send the first text right then and there
      EnrollTextWorker.perform_async(
                                     queue_id, 
                                     phone, 
                                     teacher, 
                                     school_signature, 
                                     I18n.t("defaults.child"),  
                                     text_in=true,
                                     locale=I18n.locale
                                    )

      email_admins "A new user with phone #{phone} has enrolled by texting in", \
             "Phone: #{phone}<br/>Message:#{params[:Body]}<br/>School: #{school_signature}"
    end
  end


  post '/enroll' do
    "yo, we're at /enroll now!"
  end

  post '/' do
    "yo, we're at / now!"
  end

















end









