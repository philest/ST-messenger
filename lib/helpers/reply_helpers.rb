require_relative 'name_codes'
module MessageReplyHelpers
  include NameCodes
  # TODO: add Spanish words here
  DAY_RQST        = /day\d+/i
  HELP_RQST       = /(help)|(who is this)|(who's this)|(who are you)|(ayuda)|(quien)|(quién)|(learn)|(whos this)|(who this)/i
  STOP_RQST       = /(stop)/i
  UNSUBSCRIBE_RQST = /(unsubscribe)|(quit)|(mute)|(parada)|(dejar)|(alto)|(cancel)|(quit)/i
  THANK_MSG       = /(thank you)|(thanks)|(thank)|(thx)|(thnks)|(thank u)|(gracias)/i
  HAHA_MSG        = /((ha){2,})|((ja){2,})/i 
  ROBOT_MSG       = /(robot)|(bot)|(automatic)|(automated)|(computer)|(human)|(person)|(humano)/i
  LOVE_MSG        = /(love)|(like)|(enjoy)|(amo)|(ama)|(aman)|(gusta)/i
  EMOTICON_MSG    = /(:\))|(:D)|(;\))|(:p)/
  OK_MSG          = /(^\s*ok\s*$)|(^\s*okay\s*$)|(^\s*k\s*$)|(^\s*okk\s*$)|(^\s*bueno\s*$)/i
  GO_MSG          = /(\A\s*GO\s*\z)/i
  ENROLL_MSG      = /(\A\s*STORY\s*\z)|(\A\s*CUENTO\s*\z)/i
  FEATURE_PHONES  = /(\A\s*SMS\s*\z)|(\A\s*TEXT\s*\z)|(\A\s*TEXTO\s*\z)/i
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

      # should I update story_number to 1? 
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

      puts "In reply_helpers, destroying user #{sms_user.inspect}..."
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
             body.match GO_MSG or 
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
    when STOP_RQST
      user.state_table.update(subscribed?: false, unsubscribed_on: Time.now.utc)
      if user.platform == 'fb'
        I18n.t 'user_response.stop'
      else
        ''
      end
    when LINK_CODE
      # logic for connecting the person to their phone account and school....
      if user.state_table.story_number == 0 && user.platform == 'fb' && LinkedIn_profiles(user, body)
        puts "FROM GET_REPLY!!!"
        StartDayWorker.perform_async(user.fb_id, platform='fb')
        # MessageWorker.perform_async(user.fb_id, 'day1', 'greeting', 'fb')
      end
      ''
    when GO_MSG
      if user.state_table.subscribed? == false
        user.state_table.update(subscribed?: true,
                             num_reminders: 0,
                             last_story_read?: true,
                             last_script_sent_time: nil,
                             last_reminded_time: nil
                            )
        I18n.t 'scripts.subscription.resubscribe'
      else
        # send their next story
        # script_name = "day" + user.state_table.story_number.to_s
        # have to do modulo here too......
        # but this time they're still subscribed, so how does that change things?
        st_no = user.state_table.story_number
        last_unique = user.state_table.last_unique_story
        last_unique_read = user.state_table.last_unique_story_read?

        if last_unique_read == false # signifies that our last story was the "unique" exception
          puts "the last unique story wasn't read, so we must send that one (bot.rb)"
          user.state_table.update(last_unique_story_read?: true)
          user_day = "day#{last_unique}"
          MessageWorker.perform_in(2.seconds, user.fb_id, user_day, :storysequence, 'fb')

        elsif st_no > $story_count # but we have read our last unique story
          # get the button we sent before
          mod = (st_no % $story_count) + 1 # just to be 1-indexed
          user_day = (mod == 1) ? 2 : mod
          user_day = "day#{user_day}"
          MessageWorker.perform_in(2.seconds, user.fb_id, user_day, :storysequence, 'fb')

        else # PERFORM REGULAR FUNCTION bc they still haven't gone through all stories 
          user_day = "day#{st_no}"
          MessageWorker.perform_in(2.seconds, user.fb_id, user_day, :storysequence, 'fb')
        end
        return ''

        # MessageWorker.perform_async(user.fb_id, script_name, :storysequence, 'fb') if user.platform == 'fb'
        # return ''
      end
    when ENROLL_MSG
      # update story number! because you'll have just sent the first story.
      user.update(platform: 'sms')
      user.state_table.update(subscribed?: true, story_number: 2)
      trans_code = teacher_school_messaging('scripts.enrollment.sms_optin.__poc__', user)
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
    when UNSUBSCRIBE_RQST
      user.state_table.update(subscribed?: false, unsubscribed_on: Time.now.utc)
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
      # check if user is one story 1 and unsubscribed... 
      if user.state_table.story_number == 1 and user.state_table.subscribed? == false and ['sms', 'feature'].include? user.platform
        # get this person's first_name, last_name on the phone, dawg! 
        terms = body.split(' ')
        if terms.size < 1
          return ''
        elsif terms.size == 1 # just the first name
          first_name = terms.first[0].upcase + terms.first[1..-1]
          user.update(first_name: first_name)
        elsif terms.size > 1 # first and last names, baby!!!!!! it's a gold mine over here!!!!
          first_name = terms.first[0].upcase + terms.first[1..-1] 
          last_name = terms[1..-1].inject("") {|sum, n| sum+" "+(n[0].upcase+n[1..-1])}.strip
          user.update(first_name: first_name, last_name: last_name)
        end
        # now do all the enrollment stuff
        user.update(platform: 'sms')
        user.state_table.update(subscribed?: true, story_number: 2)
        trans_code = teacher_school_messaging('scripts.enrollment.sms_optin.__poc__', user)
        I18n.t trans_code

      else
        return ''
      end





      
      # if body.include? "?"
      #   I18n.t 'user_response.default'
      # else
      #   ''
      # end
    end
  end


end