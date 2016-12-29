# require 'createsend'
require 'sidekiq'
require 'dotenv'
Dotenv.load if ['development', 'test'].include? ENV['RACK_ENV']

class NotifyTeacherWorker
  include Sidekiq::Worker


  def new_users_notification(teacher)
    last_notified = teacher.notified_on.nil? ? teacher.enrolled_on : teacher.notified_on

    named = User.where(teacher: teacher).where{enrolled_on > last_notified}.exclude(first_name: nil).all
    unnamed = User.where(teacher: teacher).where{enrolled_on > last_notified}.where(first_name: nil).all
    count = named.size + unnamed.size
    family = count > 1 ? 'families' : 'family'
    quicklink = teacher.quicklink


    if count == 0
      puts "no new users signed up"
      return
    end

    if named.size > 0
      if named.size == 1
        list_o_names = named.first.first_name
        list_o_names += " #{named.first.last_name.to_s}" if not named.first.last_name.nil?
      elsif named.size == 2
        list_o_names = named.first.first_name
        list_o_names += " #{named.first.last_name.to_s}" if not named.first.last_name.nil?
        list_o_names += " and #{named.last.first_name}"
        list_o_names += " #{named.last.last_name.to_s}" if not named.last.last_name.nil?
      else
        last_user = named.pop
        list_o_names = named.inject('') do |string, user|
          str = user.first_name.to_s
          str += " #{user.last_name.to_s}" if not user.last_name.nil?
          str += ", "
          string += str
        end

        last_u_name = last_user.first_name
        last_u_name += " #{last_user.last_name.to_s}" if not last_user.last_name.nil?

        if unnamed.size > 0
          list_o_names += "#{last_u_name}, and #{unnamed.size} others"
        else
          list_o_names += "and #{last_u_name}"
        end

      end
    else # we only have unnamed users...
      list_o_names = "See who"
    end # if named.size > 0

    puts teacher.signature, teacher.email, count, family, list_o_names, quicklink

    new_users_notification_helper(teacher.signature, teacher.email, count, family, list_o_names, quicklink)
  end

  def new_users_notification_helper(sig, email, count, family, list_o_names, quicklink)
    HTTParty.post(
      ENV['ST_ENROLL_WEBHOOK'] + '/update_teacher',
      body: {
        sig: sig,
        email: email,
        count: count,
        family: family,
        list_o_names: list_o_names,
        quicklink: quicklink
      }
    )

    # # Authenticate with your API key
    # auth = { :api_key => ENV['CREATESEND_API_KEY'] }
    # # The unique identifier for this smart email
    # smart_email_id = '98b9048d-a381-445e-8d21-65a3a5cb2b37'

    # # Create a new mailer and define your message
    # tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)

    #   message = {
    #     'To' => email,
    #     'Data' => {
    #       'signature' => sig,
    #       'family_count' => count,
    #       'family_or_families' => family,
    #       'list_of_families' => list_o_names,
    #       'quicklink' => quicklink
    #     }
    #   }
    # # Send the message and save the response
    # response = tx_smart_mailer.send(message)
  end

  def perform(teacher_id, msg_type='NEW_USERS_NOTIFICATION')
    teacher = Teacher.where(id: teacher_id).first
    if teacher.nil?
      return
    end

    case msg_type
    when 'NEW_USERS_NOTIFICATION'
      new_users_notification(teacher)
    end

    teacher.update(notified_on: Time.now.utc)

  end # perform


end












