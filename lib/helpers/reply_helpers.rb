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
  ENGLISH_PLZ     = /(english)|(ingles)|(inglés)/i
  SPANISH_PLZ     = /(spanish)|(espanol)|(español)/i

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
    when ENGLISH_PLZ
      user.update(locale: 'en')
      "Got it! We'll send you English stories instead."
    when SPANISH_PLZ
      user.update(locale: 'es')
      "Bien! Le enviaremos cuentos en español :)"
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