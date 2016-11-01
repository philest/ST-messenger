require_relative '../helpers/contact_helpers'
require_relative '../workers/schedule_worker'

module Birdv
  module DSL
    module Texting
      include ContactHelpers

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


      def translate_sms(phone, text)
        usr = User.where(phone: phone).first
        I18n.locale = usr.locale

        if text.nil? or text.empty? then 
          return text   
        end

        if text[0] == "*"
          return text[1..-1]
        end

        new_text = teacher_school_messaging(text, usr)

        next_day = nil # by default

        # Translate the weekday here. do it, why don't you?
        # if it matches a day of the week thing
        # window_text_regex = /scripts.buttons.window_text(\[\d+\])/i
        window_text_regex = /scripts.outro.(teacher|school|none)(\[\d+\])/i
        if window_text_regex.match(new_text)
          # get the code thing to transfer over
          bracket_index = $2.to_s
          just_the_text_regex = /.*[^\[\d+\]]/i
          just_the_text = just_the_text_regex.match(new_text).to_s
          # ok, so now we have the bracket and the text
          # so now we want to get this_week or next_week

          # first, grab their current day of the week
          
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

          new_text = just_the_text + week + bracket_index
        end # window_text_regex.match

        # other indexing stuff. ay yay yay....
        re_index = /\[(\d+)\]/i
        match = re_index.match(new_text)
        if match
          index = $1
          code_regex = /.*[^\[\d+\]]/i
          translation_code = code_regex.match(new_text)
          translation_array = I18n.t translation_code.to_s.downcase
          if translation_array.is_a? Array
            translation = name_codes translation_array[index.to_i], phone, next_day
            puts translation
            return translation
          else
            notify_admins('problems translating', translation_array)
            raise StandardError, 'array indexing with translation failed, check your translation logic bitxh'
          end
        end
        trans = I18n.t new_text

        if trans.include? 'translation missing'
          notify_admins(trans, '')
        end

        puts "translation = #{trans}"
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

      # just for testing purposes....
      def send
        puts "a fake implementation of `send`"
      end


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
        translated_text = translate_sms(phone, text)
        if translated_text == false
          puts "something went wrong, can't translate this text (likely, the phone # doesn't belong to a user in the system)"
          return
        end

        TextingWorker.perform_async(translated_text, phone, ENV['ST_MAIN_NO'], 'SMS',
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

        TextingWorker.perform_async(img_url, phone, ENV['ST_MAIN_NO'], 'MMS',
                                'script' => @script_name, 
                                'sequence' => next_sequence_name, 
                                'last_sequence'=> last_sequence_name) 

      end



    end # module MMS
  end # module DSL
end # module Birdv