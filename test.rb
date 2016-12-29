require 'httparty'
require_relative 'config/initializers/aws'
require_relative 'bin/local'


s = School.where(signature: "StoryTime", code: "TEST|TEST-es").first
t = Teacher.where(signature: "God").first
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

worker = NotifyTeacherWorker.new

worker.new_users_notification(t)


