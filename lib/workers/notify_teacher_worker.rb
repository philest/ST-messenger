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

    new_users = User.where{enrolled_on > last_notified}.exclude(first_name: nil).all

    if new_users.count == 0
      return
    end

    last_user = new_users.pop

    list_o_names = new_users.inject('') do |string, user|
      str = user.first_name.to_s
      str += " #{user.last_name.to_s}" if not user.last_name.nil?
      str += ", "
      string += str
    end

    last_u_name = last_user.first_name
    last_u_name += " #{last_user.last_name.to_s}" if not last_user.last_name.nil?

    list_o_names += "and #{last_u_name}"

    count = new_users.size
    family = count > 1 ? 'families' : 'family'

    # Authenticate with your API key
    auth = { :api_key => ENV['CREATESEND_API_KEY'] }
    # The unique identifier for this smart email
    smart_email_id = '98b9048d-a381-445e-8d21-65a3a5cb2b37'

    # Create a new mailer and define your message
    tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)
    message = {
      'To' => 'josedmcpeek@gmail.com',
      'Data' => {
        'signature' => teacher.signature,
        'family_count' => count.to_s,
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












