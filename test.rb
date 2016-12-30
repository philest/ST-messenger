require 'httparty'
require_relative 'config/initializers/aws'
require_relative 'bin/local'
require_relative 'lib/workers'

s = School.where(signature: "ST Prep").first
t = Teacher.where(email: "josedmcpeek@gmail.com").first
t.update(notified_on: Time.now - 1.week)
# t.signup_user(User.create(first_name: "David"))
# t.signup_user(User.create(first_name: "Aubrey", last_name: "Wahl"))
# t.signup_user(User.create(first_name: "Phil"))
t.signup_user(User.create())
t.signup_user(User.create())
t.signup_user(User.create())
t.signup_user(User.create())


# 1. no names
# 2. only names
# 3. both names and unnamed
# 

require_relative 'lib/workers/notify_teacher_worker'

# require 'createsend'

# # Authenticate with your API key
# auth = { :api_key => '3178e57316547310895b48c195da986ee9d65a2bab76724d' }

# # The unique identifier for this smart email
# smart_email_id = '98b9048d-a381-445e-8d21-65a3a5cb2b37'

# # Create a new mailer and define your message
# tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)
# message = {
#   'To' => 'Phil Esterman <david@joinstorytime.com>',
#   'Data' => {
#     'x-apple-data-detectors' => 'x-apple-data-detectorsTestValue',
#     'href^="tel"' => 'href^="tel"TestValue',
#     'href^="sms"' => 'href^="sms"TestValue',
#     'owa' => 'owaTestValue',
#     'family_count' => 'family_countTestValue',
#     'family_or_families' => 'family_or_familiesTestValue',
#     'list_of_families' => 'list_of_familiesTestValue',
#     'quicklink' => 'quicklinkTestValue',
#     'signature' => 'signatureTestValue'
#   }
# }

# # Send the message and save the response
# response = tx_smart_mailer.send(message)


worker = NotifyTeacherWorker.new

worker.new_users_notification(t)


