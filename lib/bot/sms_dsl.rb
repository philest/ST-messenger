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



      def name_codes(str, phone, day)
        user = User.where(:phone => phone).first

        if user
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

          if !day.nil?
            weekday = I18n.t('week')[day]
            str = str.gsub(/__DAY__/, weekday)
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

        next_day = nil # by default

        # Translate the weekday here. do it, why don't you?
        # if it matches a day of the week thing
        window_text_regex = /scripts.buttons.window_text(\[\d+\])/i
        if window_text_regex.match(text)
          # get the code thing to transfer over
          bracket_index = $1.to_s
          just_the_text_regex = /.*[^\[\d+\]]/i
          just_the_text = just_the_text_regex.match(text).to_s
          # ok, so now we have the bracket and the text
          # so now we want to get this_week or next_week

          # first, grab their current day of the week
          require_relative '../workers/schedule_worker'
          sw = ScheduleWorker.new
          schedule = sw.get_schedule(@script_day)

          # what is our current day?
          current_date = sw.get_local_time(Time.now.utc, usr.tz_offset)
          current_weekday = current_date.wday

          next_day = schedule[0] # the first part of the next week by default
          week = '.next_week'
          schedule.each do |day|
            # make me proud
            if day > current_weekday
              next_day = day
              week = '.this_week'
              break
            end
          end

          text = just_the_text + week + bracket_index
        end # window_text_regex.match

        # other indexing stuff. ay yay yay....
        re_index = /\[(\d+)\]/i
        match = re_index.match(text)
        if match
          index = $1
          code_regex = /.*[^\[\d+\]]/i
          translation_code = code_regex.match(text)
          translation_array = I18n.t translation_code.to_s.downcase
          if translation_array.is_a? Array
            translation = name_codes translation_array[index.to_i], phone, next_day
            puts translation
            return translation
          else
            raise StandardError, 'array indexing with translation failed, check your translation logic bitxh'
          end
        end
        trans = I18n.t text
        puts "trans = #{trans}"
        if trans.is_a? Array
          return name_codes trans[@script_day - 1], phone, next_day
        else
          return name_codes trans, phone, next_day
        end
        
      rescue NoMethodError => e
        p e.message + " usr doesn't exist, can't translate"
        return false

      rescue StandardError => e
        p e.message
        return false
      end # translate_mms

      # perhaps add a sequence_name, script_name here and include those params in the post for the callback

      # def next_sequence( phone, sequence_name )
      #   user = User.where( phone: phone ).first
      #   user.state_table.update( next_sequence: sequence_name )
      #   return true # or whatever
      # end

      def send_sms( phone, text, next_sequence_name=nil )
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
            script: @script_name,
            next_sequence: next_sequence_name
        })
      end

      def send_mms( phone, img_url, next_sequence_name=nil )
        img_url = translate_sms(phone, img_url)

        HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/mms", 
          body: {
            recipient: phone,
            img_url: img_url,
            script: @script_name,
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