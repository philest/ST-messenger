# require 'spec_helper'
# require 'bot/dsl'
# require 'bot/curricula'
# require 'timecop'
# require 'workers'
# require 'sidekiq/testing'


# describe 'teacher notifications' do

#     context 'notification content' do
#       before(:each) {
#         # create a school
#         @school = School.create(signature: "ST Prep", code: 'school|school-es')
#         # create a teacher
#         @teacher = Teacher.create(signature: "Mr. Teacher", email: "teacher@school.edu")
#         @school.signup_teacher(@teacher)
#         @teacher.reload

#         @named = User.create(first_name: 'David', last_name: 'McPeek')
#         @unnamed = User.create

#         @nw = NotifyTeacherWorker.new
#       }
#       # test with 
#       #   1. many named, no unnamed
#       #   2. many unnamed, no named
#       #   3. 1 named, many unnamed
#       #   4. 1 unnamed, many named
#       #   5. first name only
#       #   6. many named, many unnamed


#       it "does many named, many unnamed correctly" do
#         user1 = User.create(first_name: "Phil")
#         user2 = User.create(first_name: "Aubrey", last_name: "Wahl")
#         args = [@teacher.signature, @teacher.email, 6, 'families', 'David McPeek, Phil, Aubrey Wahl, and 3 others', @teacher.quicklink]
#         expect(@nw).to receive(:new_users_notification_helper).with(*args).once

#         @teacher.signup_user(@named)
#         @teacher.signup_user(user1)
#         @teacher.signup_user(user2)
#         @teacher.signup_user(User.create)
#         @teacher.signup_user(User.create)
#         @teacher.signup_user(User.create)
#         @nw.perform(@teacher.id, 'NEW_USERS_NOTIFICATION')
#       end

#       it "does many named, no unnamed correctly" do
#         user1 = User.create(first_name: "Phil")
#         user2 = User.create(first_name: "Aubrey", last_name: "Wahl")
#         args = [@teacher.signature, @teacher.email, 3, 'families', 'David McPeek, Phil, and Aubrey Wahl', @teacher.quicklink]
#         expect(@nw).to receive(:new_users_notification_helper).with(*args).once

#         @teacher.signup_user(@named)
#         @teacher.signup_user(user1)
#         @teacher.signup_user(user2)
#         @nw.perform(@teacher.id, 'NEW_USERS_NOTIFICATION')
#       end

#       it "does many unnamed, no named correctly" do
#         user1 = User.create()
#         user2 = User.create()
#         user3 = User.create()
#         args = [@teacher.signature, @teacher.email, 3, 'families', 'See who', @teacher.quicklink]
#         expect(@nw).to receive(:new_users_notification_helper).with(*args).once

#         @teacher.signup_user(user1)
#         @teacher.signup_user(user2)
#         @teacher.signup_user(user3)
#         @nw.perform(@teacher.id, 'NEW_USERS_NOTIFICATION')
#       end

#       it "does unnamed, no named correctly" do
#         args = [@teacher.signature, @teacher.email, 1, 'family', 'See who', @teacher.quicklink]
#         expect(@nw).to receive(:new_users_notification_helper).with(*args).once

#         @teacher.signup_user(@unnamed)

#         @nw.perform(@teacher.id, 'NEW_USERS_NOTIFICATION')
#       end

#       it "does named, no unnamed correctly" do
#         args = [@teacher.signature, @teacher.email, 1, 'family', 'David McPeek', @teacher.quicklink]
#         expect(@nw).to receive(:new_users_notification_helper).with(*args).once

#         @teacher.signup_user(@named)

#         @nw.perform(@teacher.id, 'NEW_USERS_NOTIFICATION')
#       end

#       it "does first name" do
#         user = User.create(first_name: "Pariah")
#         args = [@teacher.signature, @teacher.email, 1, 'family', 'Pariah', @teacher.quicklink]
#         expect(@nw).to receive(:new_users_notification_helper).with(*args).once

#         @teacher.signup_user(user)

#         @nw.perform(@teacher.id, 'NEW_USERS_NOTIFICATION')
#       end

#   end


#   # this is the most important thing to test
#   context 'schedule' do
#     # 1. teacher enrolls. 
#     # 2. next day - no notifications
#     # 3. add users
#     # 4. TEACHERS WON'T BE NOTIFIED TWICE IN A DAY

#     before(:each) {
#       # create a school
#       @school = School.create(signature: "ST Prep", code: 'school|school-es')
#       # create a teacher
#       @teacher = Teacher.create(signature: "Mr. Teacher", email: "teacher@school.edu")
#       @school.signup_teacher(@teacher)
#     }

#     it "does not call the helper with no new users" do
#       Sidekiq::Testing.fake! do
#         nw = NotifyTeacherWorker.new
#         expect(nw).not_to receive(:new_users_notification_helper)
#         nw.perform(@teacher.id, 'NEW_USERS_NOTIFICATION')
#       end
#     end

#     it "calls the helper with new users" do
#       Sidekiq::Testing.fake! do
#         nw = NotifyTeacherWorker.new
#         expect(nw).to receive(:new_users_notification_helper).once
#         @teacher.signup_user(User.create)
#         nw.perform(@teacher.id, 'NEW_USERS_NOTIFICATION')
#       end
#     end

#     it "doesn't ever call NotifyTeacherWorker more than twice in a day" do
#       Sidekiq::Testing.fake! do
#         expect {
#           now = Time.now.utc
#           24.times do |n|
#             Timecop.freeze(now + n.hours)

#             puts "time now = #{Time.now.utc.hour}"

#             # copied straight from clock file
#             if Time.now.utc.hour == 12 # 4am PST
#               puts "now = #{Time.now.utc}"
#               Teacher.each do |t|
#                 puts "teacher = #{t.inspect}"
#                 # we don't want any repeats
#                 if t.notified_on.nil? or (Time.now.utc - t.notified_on.utc) > 6.hours
#                   NotifyTeacherWorker.perform_async(t.id, 'NEW_USERS_NOTIFICATION')
#                 end
#               end
#             end
#           end # 24.times do
#         }.to change(NotifyTeacherWorker.jobs, :size).by 1
#       end

#     end

#     it "doesn't call NotifyTeacherWorker if it's already been called that day" do
#       Timecop.freeze(Time.new(2016, 12, 31, 7))
#       puts "time.now.utc = #{Time.now.utc}"
#       @teacher.update(notified_on: Time.now.utc)
#       Sidekiq::Testing.fake! do
#         expect {
#           Timecop.freeze(Time.new(2016, 12, 31, 12))

#           expect(Time.now.utc - @teacher.notified_on.utc).to be < 6.hours

#           Teacher.each do |t|
#             puts "teacher = #{t.inspect}"
#             # we don't want any repeats
#             if t.notified_on.nil? or (Time.now.utc - t.notified_on.utc) > 6.hours
#               NotifyTeacherWorker.perform_async(t.id, 'NEW_USERS_NOTIFICATION')
#             end
#           end

#         }.to change(NotifyTeacherWorker.jobs, :size).by 0
#       end
#     end
#   end




# end