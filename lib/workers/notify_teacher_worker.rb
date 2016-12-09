require 'createsend'
require 'sidekiq'
require 'dotenv'
Dotenv.load

class NotifyTeacherWorker
  include Sidekiq::Worker

  def teacher_signup_success(teacher)
    # Authenticate with your API key
    auth = { :api_key => ENV['CREATESEND_API_KEY'] }

    # The unique identifier for this smart email
    smart_email_id = 'a7ad322e-3631-4bf5-af7e-c85ffddbf4fd'

    # Create a new mailer and define your message
    tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)
    message = {
      'To' => 'josedmcpeek@gmail.com',
      'Data' => {
        'signature' => teacher.signature,
      }
    }

    # Send the message and save the response
    response = tx_smart_mailer.send(message)

  end

  def new_users_notification(teacher)
    last_notified = teacher.notified_on.nil? ? teacher.enrolled_on : teacher.notified_on

    named = User.where{enrolled_on > last_notified}.exclude(first_name: nil).all
    unnamed = User.where{enrolled_on > last_notified}.where(first_name: nil).all
    count = named.size + unnamed.size
    family = count > 1 ? 'families' : 'family'

    if count == 0
      return
    end

    if named.size > 0
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

    else # we only have unnamed users...
      list_o_names = "See who"
    end # if named.size > 0

    new_users_notification_helper(teacher.signature, count, family, list_o_names)

  end

  def new_users_notification_helper(sig, count, family, list_o_names)
    # Authenticate with your API key
    auth = { :api_key => ENV['CREATESEND_API_KEY'] }
    # The unique identifier for this smart email
    smart_email_id = '98b9048d-a381-445e-8d21-65a3a5cb2b37'

    # Create a new mailer and define your message
    tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)

      message = {
        'To' => 'supermcpeek@gmail.com',
        'Data' => {
          'signature' => sig,
          'family_count' => count,
          'family_or_families' => family,
          'list_of_families' => list_o_names
        }
      }
    # Send the message and save the response
    response = tx_smart_mailer.send(message)
  end


  def perform(teacher_id, msg_type)
    teacher = Teacher.where(id: teacher_id).first
    if teacher.nil?
      return
    end

    case msg_type
    when 'TEACHER_SIGNUP_SUCCESS'
      teacher_signup_success(teacher)
    when 'NEW_USERS_NOTIFICATION'
      new_users_notification(teacher)
    end

    teacher.update(notified_on: Time.now.utc)

  end # perform


end












