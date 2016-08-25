module Birdv

  module DSL

    module SMS

      def get_curriculum_version(recipient)
        user = User.where(phone: recipient).first
        if user
          return user.curriculum_version
        else # default to the 0th version
          return 0
        end
      end


      def get_locale(recipient)
        user = User.where(phone: recipient).first
        if user
          return user.locale
        else # default to the 0th version
          return 'en'
        end
      end



      def name_codes(str, phone)
        user = User.where(:phone => phone).first

        if user
          parent  = user.first_name.nil? ? "" : user.first_name
          child   = user.child_name.nil? ? "your child" : user.child_name.split[0]
          
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
        else # just return what we started with. It's 
          str = str.gsub(/__TEACHER__/, 'StoryTime')
          str = str.gsub(/__PARENT__/, '')
          str = str.gsub(/__CHILD__/, 'your child')
          return str
        end
      end

      def translate_sms(phone, text)
        usr = User.where(phone: phone).first
        I18n.locale = usr.locale

        if text.nil? or text.empty? then 
          return text   
        end

        trans = I18n.t text
        puts "trans = #{trans}"
        if trans.is_a? Array
          return name_codes trans[@script_day - 1], phone 
        else
          return name_codes trans, phone
        end
        
      rescue NoMethodError => e
        p e.message + " usr doesn't exist, can't translate"
        return false
      end # translate_mms

      # perhaps add a sequence_name, script_name here and include those params in the post for the callback

      # def next_sequence( phone, sequence_name )
      #   user = User.where( phone: phone ).first
      #   user.state_table.update( next_sequence: sequence_name )
      #   return true # or whatever
      # end

      def send_sms_helper( phone, text, script_name, next_sequence_name )
        puts "in send_sms_helper, next_sequence is #{next_sequence_name}"
        puts "in send_sms_helper, script_name is #{script_name}"

        text = translate_sms(phone, text)
        if text == false
          puts "something went wrong, can't translate this text (likely, the phone # doesn't belong to a user in the system)"
          return
        end
        # TODO: change this url to /sms.....
        HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/txt", 
          body: {
            recipient: phone,
            text: text, 
            script: script_name,
            next_sequence: next_sequence_name
        })
      end

      def send_mms_helper( phone, img_url, script_name, next_sequence_name )
        img_url = translate_sms(phone, img_url)

        HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/mms", 
          body: {
            recipient: phone,
            img_url: img_url,
            script: script_name,
            next_sequence: next_sequence_name
        })
      end

      # need to have a smarter way to update last_story_read
      # what if we went back to the send_story function which handled everything? 
      # for now, just update it somewhere


      # def send_helper(phone, to_send, script_day, type)
      #   # create a story() function for mms, which incorporates delays.
      #   case type
      #   when 'sms'

      #     text = translate_sms( phone, to_send )
      #     if text == false
      #       puts "something went wrong, can't translate this text (likely, the phone # doesn't belong to a user in the system)"
      #       return
      #     end
      #     HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/txt", 
      #       body: {
      #         recipient: phone,
      #         text: text
      #     })

      #   when 'mms'
      #     HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/mms", 
      #       body: {
      #         recipient: phone,
      #         img_url: to_send
      #     })
      #   end
      # end # send_helper


    end # module MMS

  end # module DSL

end # module Birdv