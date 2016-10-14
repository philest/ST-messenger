require 'spec_helper'
require 'helpers/reply_helpers'
include MessageReplyHelpers

describe MessageReplyHelpers do

  context 'get_reply' do

    it "sends a reply to someone who is unsubscribed but is SMS and at story = 1" do
      user = User.create(platform: 'sms')
      user.state_table.update(story_number: 1, subscribed?: false)
      msg = "english please?"
      reply = get_reply(msg, user)
      expect(reply).to eq("Got it! We'll send you English stories instead.")
    end

    it "sends a reply to someone who is new on FB" do
      user = User.create(platform: 'fb')
      user.state_table.update(story_number: 0, subscribed?: false)
      msg = "english please?"
      reply = get_reply(msg, user)
      expect(reply).to eq("Got it! We'll send you English stories instead.")
      user.state_table.update(story_number: 1)
      msg = "yes please stop?"
      reply = get_reply(msg, user)
      expect(reply).to eq("")

    end

    it "doesn't send a reply to someone who is unsubscribed and sends a random thing" do
      user = User.create(platform: 'fb')
      user.state_table.update(story_number: 2, subscribed?: false)
      msg = "thanks :)"
      reply = get_reply(msg, user)
      expect(reply).to eq("")

      user = User.create(platform: 'sms')
      user.state_table.update(story_number: 2, subscribed?: false)
      msg = "thanks :)"
      reply = get_reply(msg, user)
      expect(reply).to eq("")
    end

  end

  context "LinkedIn_profiles" do
    it "returns false for non-matching codes" do
      fb_user  = User.create(fb_id: '1234')
      code = "#anormalfuckingcode"
      sms_user = User.create(platform: 'sms')
      sms_user.update(code: code)
      expect(LinkedIn_profiles(fb_user, "#notarealcode")).to eq false
    end

    it "returns true for matching codes" do 
      fb_user  = User.create(fb_id: '1234')
      code = "#anormalfuckingcode"
      sms_user = User.create(platform: 'sms')
      sms_user.update(code: code)
      expect(LinkedIn_profiles(fb_user, code)).to eq true
    end

    it "deletes sms_user" do 
      fb_user  = User.create(fb_id: '1234')
      code = "#anormalfuckingcode"
      sms_user = User.create(platform: 'sms')
      sms_user.update code: code
      LinkedIn_profiles(fb_user, code)
      expect(User.where(code: code, platform: 'sms').first).to be nil
    end

    it "copies sms_user data to fb_user" do 
      fb_user = User.create do |u|
        u.phone       = nil
        u.fb_id       = "12345"
        u.send_time   = Time.now
        u.enrolled_on = Time.now
      end
      fb_user.update code: "a fake-ass code"
      
      code = "#anormalfuckingcode"
      sms_user = User.create do |u|
        u.phone       = "8186897323"
        u.code        = code
        u.send_time   = Time.parse("2016-06-22 23:00:00 UTC")
        u.enrolled_on = Time.parse("2016-06-22 23:00:00 UTC")
        u.child_name  = "Bucky the Vampire"
        u.child_age   = -1
        u.platform    = 'sms'
      end

      sms_user.update code: code

      teacher = Teacher.create
      teacher.add_user(sms_user)
      sms_user.teacher = teacher
      school  = School.create
      school.add_user(sms_user)
      sms_user.school = school

      LinkedIn_profiles(fb_user, code)
      fb_user.reload

      expect(fb_user.phone).to eq "8186897323"
      expect(fb_user.code).to eq code
      # expect(fb_user.send_time).to eq Time.parse("2016-06-22 23:00:00 UTC")
      expect(fb_user.enrolled_on).to eq Time.parse("2016-06-22 23:00:00 UTC")
      expect(fb_user.child_name).to eq "Bucky the Vampire"
      expect(fb_user.child_age). to eq -1

      expect(fb_user.school_id).to eq school.id
      expect(fb_user.teacher_id).to eq teacher.id
      expect(teacher.users).to include fb_user
      expect(school.users).to include fb_user

      expect(fb_user.platform).to eq 'fb'

    end

  end

end
