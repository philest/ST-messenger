module MessageReplyHelpers
  # TODO: add Spanish words here
  DAY_RQST        = /day\d+/i
  HELP_RQST       = /(help)|(who is this)|(who's this)|(who are you)|(ayuda)|(quien)|(quién)|(learn)/i
  STOP_RQST       = /(stop)|(unsubscribe)|(quit)|(mute)|(parada)|(dejar)|(alto)/i
  THANK_MSG       = /(thank you)|(thanks)|(thank)|(thx)|(thnks)|(thank u)|(gracias)/i
  HAHA_MSG        = /(haha)+|(jaja)+/i 
  ROBOT_MSG       = /(robot)|(bot)|(automatic)|(automated)|(computer)|(human)|(person)|(humano)/i
  LOVE_MSG        = /(love)|(like)|(enjoy)|(amo)|(ama)|(aman)|(gusta)/i
  EMOTICON_MSG    = /(:\))|(:D)|(;\))|(:p)/
  OK_MSG          = /(^\s*ok\s*$)|(^\s*okay\s*$)|(^\s*k\s*$)|(^\s*okk\s*$)|(^\s*bueno\s*$)/i
  RESUBSCRIBE_MSG = /(\A\s*GO\s*\z)|(libros)/i
  ENROLL_MSG      = /(\A\s*TEXT\s*\z)|(\A\s*STORY\s*\z)|(\A\s*CUENTO\s*\z)/i
  FEATURE_PHONES  = /\A\s*SMS\s*\z/i
  LINK_CODE       = /\A\s*@\S+\s*\z/i

  def LinkedIn_profiles(fb_user, code)
    # bitches!
    return false if code.nil?

    sms_user = User.where(code: code).first
    # wrangle fb_user's profile information into the same user
    # updating the phone user though. eventually delete the facebook user so there's only one. 
    # probably should delete the phone user because we're updating db user, y'know?

    if sms_user
      # we're NOT switching state_tables because we want fb_user to keep that
      phone = sms_user.phone
      sms_user.update(phone: nil) # otherwise we have a key validation exception
      fb_user.update(phone:           phone,
                     code:            sms_user.code,
                     enrolled_on:     sms_user.enrolled_on,
                     teacher_id:      sms_user.teacher_id,
                     school_id:       sms_user.school_id,
                     child_name:      sms_user.child_name,
                     child_age:       sms_user.child_age)

      school  = sms_user.school
      teacher = sms_user.teacher

      # connect school
      if school
        school.add_user(fb_user)
        fb_user.school = school
      end

      # connect teacher
      if teacher
        teacher.add_user(fb_user)
        fb_user.teacher = teacher
      end

      sms_user.destroy

      # success
      return true
    end

    # no matching code
    return false

  end



  def get_reply(body, user)
    our_reply = ''
    I18n.locale = user.locale
    # puts "body.match ENROLL_MSG = #{body.match ENROLL_MSG}"
    # if user.state_table.subscribed? == false
    #   unless body.match RESUBSCRIBE_MSG or body.match ENROLL_MSG
    #     return
    #   end
    # end
    case body
    when LINK_CODE
      # logic for connecting the person to their phone account and school....


    when RESUBSCRIBE_MSG
      if user.state_table.subscribed? == false
        user.state_table.update(subscribed?: true,
                             num_reminders: 0,
                             last_story_read?: true,
                             last_script_sent_time: nil,
                             last_reminded_time: nil
                            )
        I18n.t 'scripts.resubscribe'
      else
        ''
      end
    when ENROLL_MSG
      # update story number! because you'll have just sent the first story.
      user.state_table.update(subscribed?: true, story_number: 2)
      I18n.t 'enrollment.sms_optin'
    when FEATURE_PHONES
      user.update(platform: 'feature')
      I18n.t 'feature.messages.opt-in.confirmation'
    when HELP_RQST
      I18n.t 'user_response.help'
    when STOP_RQST
      user.state_table.update(subscribed?: false)
      I18n.t 'user_response.stop'
    when THANK_MSG
      I18n.t 'user_response.thanks'
    when HAHA_MSG
      ":D"
    when ROBOT_MSG
      I18n.t 'user_response.robot'
    when LOVE_MSG
      "^_^"
    when EMOTICON_MSG
      "^_^"  
    when OK_MSG
      ":)"    
    else #default msg 
      if body.include? "?"
        I18n.t 'user_response.default'
      else
        ''
      end
    end
  end

  module SMSReplies

      def self.name_codes(str, user)
        parent  = user.first_name.nil? ? "" : user.first_name
        I18n.locale = user.locale
        child   = user.child_name.nil? ? I18n.t('defaults.child') : user.child_name.split[0]
        
        if !user.teacher.nil?
          sig = user.teacher.signature
          teacher = sig.nil?           ? "StoryTime" : sig
        else
          teacher = "StoryTime"
        end

        if user.school
          sig = user.school.signature
          school = sig.nil?   ? "StoryTime" : sig
        else
          school = "StoryTime"
        end

        str = str.gsub(/__TEACHER__/, teacher)
        str = str.gsub(/__PARENT__/, parent)
        str = str.gsub(/__SCHOOL__/, school)
        str = str.gsub(/__CHILD__/, child)
        return str
      end

  end



end