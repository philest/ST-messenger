require_relative 'name_codes'
module MessageReplyHelpers
  include NameCodes
  # TODO: add Spanish words here
  DAY_RQST        = /day\d+/i
  HELP_RQST       = /(help)|(who is this)|(who's this)|(who are you)|(ayuda)|(quien)|(quién)|(learn)/i
  STOP_RQST       = /(stop)|(unsubscribe)|(quit)|(mute)|(parada)|(dejar)|(alto)/i
  THANK_MSG       = /(thank you)|(thanks)|(thank)|(thx)|(thnks)|(thank u)|(gracias)/i
  HAHA_MSG        = /((ha){2,})|((ja){2,})/i 
  ROBOT_MSG       = /(robot)|(bot)|(automatic)|(automated)|(computer)|(human)|(person)|(humano)/i
  LOVE_MSG        = /(love)|(like)|(enjoy)|(amo)|(ama)|(aman)|(gusta)/i
  EMOTICON_MSG    = /(:\))|(:D)|(;\))|(:p)/
  OK_MSG          = /(^\s*ok\s*$)|(^\s*okay\s*$)|(^\s*k\s*$)|(^\s*okk\s*$)|(^\s*bueno\s*$)/i
  RESUBSCRIBE_MSG = /(\A\s*GO\s*\z)|(libros)/i
  ENROLL_MSG      = /(\A\s*TEXT\s*\z)|(\A\s*STORY\s*\z)|(\A\s*CUENTO\s*\z)/i
  FEATURE_PHONES  = /\A\s*SMS\s*\z/i
  ENGLISH_PLZ     = /(english)|(ingles)|(inglés)/i
  SPANISH_PLZ     = /(spanish)|(espanol)|(español)/i

  # LINK_CODE       = /\A\s*@\S+\s*\z/i
  LINK_CODE     = /\A\s*\d{2,3}\s*\z/i


  def LinkedIn_profiles(fb_user, code)
    # bitches!
    return false if code.nil?
    code = code.to_s.downcase

    sms_user = User.where(code: code, platform: 'sms').first
    if sms_user.nil?
      sms_user = User.where(code: code, platform: 'feature').first
    end
    # wrangle fb_user's profile information into the same user
    # updating the phone user though. eventually delete the facebook user so there's only one. 
    # probably should delete the phone user because we're updating db user, y'know?

    if sms_user && sms_user.id != fb_user.id
      # we're NOT switching state_tables because we want fb_user to keep that
      phone = sms_user.phone
      sms_user.update(phone: nil) # otherwise we have a key validation exception
      code = sms_user.code
      sms_user.update(code: nil) 
      fb_user.update(phone:           phone,
                     code:            nil, # nullify the code
                     enrolled_on:     sms_user.enrolled_on,
                     teacher_id:      sms_user.teacher_id,
                     school_id:       sms_user.school_id,
                     child_name:      sms_user.child_name,
                     child_age:       sms_user.child_age)

      fb_user.state_table.update(subscribed?: true)

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

      # destroy later because of shit
      # DestroyerWorker.perform_in(5.minutes, sms_user.id)

      puts "destroying user..."
      sms_user.destroy

      # success
      return true
    end

    # no matching code
    return false
  end


  def get_reply(body, user)
    if body.nil? or body.empty?
      return ''
    end
    
    our_reply = ''
    I18n.locale = user.locale
    
    if user.state_table.subscribed? == false
      
      is_sms = (user.platform == 'sms' or user.platform == 'feature')
      story_no = user.state_table.story_number

      unless (is_sms && story_no == 1) or
             story_no == 0 or
             body.match RESUBSCRIBE_MSG or 
             body.match ENROLL_MSG or 
             body.match LINK_CODE or 
             body.match FEATURE_PHONES or
             body.match ENGLISH_PLZ or
             body.match SPANISH_PLZ
        puts "we are unsubscribed, so we're not gonna send a reply"
        return ''
      end

    end


    case body
    when LINK_CODE
      # logic for connecting the person to their phone account and school....
      if LinkedIn_profiles(user, body) && user.state_table.story_number == 0
        puts "FROM GET_REPLY!!!"
        StartDayWorker.perform_async(user.fb_id, platform='fb')
        # MessageWorker.perform_async(user.fb_id, 'day1', 'greeting', 'fb')
      end
      ''
    when RESUBSCRIBE_MSG
      if user.state_table.subscribed? == false
        user.state_table.update(subscribed?: true,
                             num_reminders: 0,
                             last_story_read?: true,
                             last_script_sent_time: nil,
                             last_reminded_time: nil
                            )
        I18n.t 'scripts.subscription.resubscribe'
      else
        ''
      end
    when ENROLL_MSG
      # update story number! because you'll have just sent the first story.
      user.update(platform: 'sms')
      user.state_table.update(subscribed?: true, story_number: 2)
      trans_code = teacher_school_messaging('enrollment.sms_optin.__poc__', user)
      I18n.t trans_code
    when FEATURE_PHONES
      user.update(platform: 'feature')
      I18n.t 'feature.messages.opt-in.confirmation'
    when ENGLISH_PLZ
      user.update(locale: 'en')
      trans_code = teacher_school_messaging('replies.english_plz.__poc__', user)
      I18n.t trans_code
    when SPANISH_PLZ
      user.update(locale: 'es')
      trans_code = teacher_school_messaging('replies.spanish_plz.__poc__', user)
      I18n.t trans_code
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
      ''
      # if body.include? "?"
      #   I18n.t 'user_response.default'
      # else
      #   ''
      # end
    end
  end


end