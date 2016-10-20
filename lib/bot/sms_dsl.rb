module Birdv

  module DSL

    module Texting

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
        puts "USING NAME_CODES IN SMS_DSL.RB"
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
          
          code = user.code
          if code.nil?
            code = "READ"
          end

          str.gsub!(/__CODE__/, code)
          str.gsub!(/__TEACHER__/, teacher)
          str.gsub!(/__PARENT__/, parent)
          str.gsub!(/__SCHOOL__/, school)
          str.gsub!(/__CHILD__/, child)
          return str
        else # just return what we started with. It's 
          str.gsub!(/__CODE__/, 'go')
          str.gsub!(/__TEACHER__/, 'StoryTime')
          str.gsub!(/__PARENT__/, '')
          str.gsub!(/__SCHOOL__/, 'StoryTime')
          str.gsub!(/__CHILD__/, 'your child')
          return str
        end
      end

      def translate_sms(phone, text)
        usr = User.where(phone: phone).first
        I18n.locale = usr.locale

        if text.nil? or text.empty? then 
          return text   
        end

        if text[0] == "*"
          return text[1..-1]
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


      def send_sms( phone, text, last_sequence_name=nil, next_sequence_name=nil )
        user = User.where(phone: phone).first
        if user.nil?
          return
        end
        user_buttons = ButtonPressLog.where(user_id:user.id) 
        # if next_sequence == nil, then they've probably already seen a sequence like nil
        we_have_a_history = !user_buttons.where(platform:user.platform,
                                               script_name:@script_name, 
                                               sequence_name:next_sequence_name).first.nil?

        if we_have_a_history
          puts "send_sms() - WE'VE ALREADY SEEN #{@script_name.upcase} #{next_sequence_name.upcase}!!!!"
          return
        end
        text = translate_sms(phone, text)
        if text == false
          puts "something went wrong, can't translate this text (likely, the phone # doesn't belong to a user in the system)"
          return
        end

        if user.platform == 'demo'
          from_no = ENV['ST_DEMO_NO']
        else
          from_no = ENV['ST_MAIN_NO']
        end

        TextingWorker.perform_async(text, phone, from_no, 'SMS',
                                'script' => @script_name, 
                                'sequence' => next_sequence_name, 
                                'last_sequence'=> last_sequence_name) 


      end

      def send_mms( phone, img_url, last_sequence_name=nil, next_sequence_name=nil )
        user = User.where(phone: phone).first
        if user.nil?
          return
        end
        user_buttons = ButtonPressLog.where(user_id:user.id) 
        # if next_sequence == nil, then they've probably already seen a sequence like nil
        we_have_a_history = !user_buttons.where(platform:user.platform,
                                               script_name:@script_name, 
                                               sequence_name:next_sequence_name).first.nil?

        if we_have_a_history
          puts "send_mms() - WE'VE ALREADY SEEN #{@script_name.upcase} #{next_sequence_name.upcase}!!!!"
          return
        end

        img_url = translate_sms(phone, img_url)
        if img_url == false
          puts "something went wrong, can't translate this text (likely, the phone # doesn't belong to a user in the system)"
          return
        end

        if user.platform == 'demo'
          from_no = ENV['ST_DEMO_NO']
        else
          from_no = ENV['ST_MAIN_NO']
        end

        TextingWorker.perform_async(img_url, phone, from_no, 'MMS',
                                'script' => @script_name, 
                                'sequence' => next_sequence_name, 
                                'last_sequence'=> last_sequence_name) 

      end



    end # module MMS

  end # module DSL

end # module Birdv