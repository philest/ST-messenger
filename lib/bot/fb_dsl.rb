require_relative '../helpers/contact_helpers'
require_relative '../workers/schedule_worker'

module Birdv
  module DSL
    module FB
      include Facebook::Messenger::Helpers 
      include ContactHelpers
      STORY_BASE_URL = 'http://d2p8iyobf0557z.cloudfront.net/'

      def url_button(title, url)
        return { type: 'web_url', title: title, url: url }
      end

      def postback_button(title, payload)
        return { type: 'postback', title: title, payload: payload.to_s }
      end

      def template_generic(btn_name, elemnts)
        tjson = { 
          message: {
            attachment: {
              type: 'template',
              payload: {
                template_type: 'generic',
                elements: elemnts
              }
            }
          }
        }
        register_fb_object(btn_name, tjson)
        return tjson
      end


      def register_fb_object(obj_key, fb_obj)
        puts 'WARNING: overwriting object #{obj_key.to_s}' if @fb_objects.key?(obj_key.to_sym)
        @fb_objects[obj_key.to_sym] =  fb_obj
      end

      def button_normal(args = {})
        assert_keys([:name, :window_text, :buttons], args)
        window_txt = args[:window_text]
        btns       = args[:buttons]
        tjson = {
          message:  {
            attachment: {
              type: 'template',
              payload: {
                template_type: 'button',
                text: window_txt,
                buttons: btns
              }
            }
          }
        }
        register_fb_object(args[:name],tjson)
        return tjson
      end

      def button_story(args = {})
        default = {subtitle:'', buttons:[]}
        assert_keys([:name, :image_url, :title], args)
        args      = default.merge(args)
        
        title     = args[:title]
        img_url   = args[:image_url]
        subtitle = args[:subtitle]

        elmnts = {title: title, image_url: img_url, subtitle: subtitle}

        # if buttons are supplied, set 'elements' field
        if !args[:buttons].empty?
          elmnts[:buttons]=args[:buttons]
        else
          puts "WARNING: no buttons in yo' button_story"
        end

        # return json hash
        template_generic(args[:name], [elmnts])
      end

      def get_curriculum_version(recipient)
        user = User.where(fb_id: recipient).first
        if user
          return user.curriculum_version
        else # default to the 0th version
          return 0
        end
      end

      def get_locale(recipient)
        user = User.where(fb_id: recipient).first
        if user
          return user.locale
        else # default to the 0th version
          return 'en'
        end
      end

    

      def text(args = {})
        assert_keys([:text], args)   
        return {message: {text:args[:text]}}
      end

      def picture(args = {})
        assert_keys([:url], args)
        return {message: {
                  attachment: {
                    type: 'image',
                    payload: {
                      url: args[:url]
                    }
                  }
                }
              }
      end

      def send_story(args = {})
        assert_keys([:library, :title, :num_pages, :recipient, :locale], args)
        library     = args[:library]
        title       = args[:title]
        num_pages   = args[:num_pages]
        recipient   = args[:recipient]
        locale      = args[:locale]
        base = STORY_BASE_URL
        locale_url_seg = (locale == 'es') ? 'es/' : ''
        num_pages.times do |i|
          url = "#{base}#{library}/#{locale_url_seg}#{title}/#{title}#{i+1}.jpg"
          puts "sending #{url}"
          fb_send_json_to_user(recipient, picture(url:url))
        end
      end


      def button(btn_name)
        if btn_name.is_a? String
          return @fb_objects[btn_name.to_sym]
        elsif btn_name.is_a? Hash 
          # TODO: ensure is not nil?
          return @fb_objects[btn_name[:name].to_sym]
        else
          return @fb_objects[btn_name]
        end
      end

      
      def story(args={})
        
        return lambda do |recipient|
          begin

            version = get_curriculum_version(recipient)
            locale  = get_locale(recipient)

            curriculum = Birdv::DSL::Curricula.get_version(version.to_i)

            # needs to be indexed at 0, so subtract 1 from the script day, which begins at 1

            # this is where we perform the modulo?????????
            storyinfo = curriculum[@script_day - 1]

            lib, title, num_pages = storyinfo

            # linear search through the stories!
            if args[:story]
              puts "we have a story!!!!!! #{args[:story]}"
              for story in curriculum
                puts "story = #{story}"
                if story[1] == args[:story] # we found it
                  lib, title, num_pages = story
                end 
              end
            end

            send_story({
              recipient:  recipient,
              library:    lib,
              title:      title,
              num_pages:  num_pages.to_i,
              locale:     locale
            })
            
            User.where(fb_id:recipient).first.state_table.update(
                                        last_story_read_time:Time.now.utc, 
                                        last_story_read?: true,
                                        last_unique_story_read?: true,
                                        num_reminders: 0,
                                        subscribed?: true)

          rescue => e
            p e.message + " failed to send user with fb_id #{recipient} a story"
            raise e
          end         
        end
      end


      def is_txt_button?(thing)
        if thing[:attachment][:payload][:text].nil? or thing[:attachment][:payload][:buttons].nil?
          return false 
        else
          return true 
        end
      rescue NoMethodError => e
        return false
      end

      def is_story_button?(thing)
        if thing[:attachment][:payload][:elements].nil? then false else true end
      rescue NoMethodError => e
        return false
      end

      def is_txt?(thing)
        if thing[:text].nil? then false else true end
      rescue NoMethodError => e
        return false
      end

      def is_img?(thing)
        if [:attachment][:type] == 'image' then true else false end
      rescue NoMethodError => e
        return false
      end

      def is_story?(thing)
        if thing.is_a? Proc then true else false end
      rescue NoMethodError => e
        p e.message
        return false 
      end

      def process_txt( fb_object, user)
          recipient = user.fb_id
          locale = user.locale
          if locale.nil? then locale = 'en' end
          I18n.locale = locale
          # translate
          translate = lambda do |str, interpolation={}|
              if str.nil? or str.empty? then 
                return str   
              end

              # when we just want the string as it is....
              if str[0] == "*"
                # if str.include? "||"
                #   if locale == 'en' 
                #   end
                # end
                return str[1..-1]
              end

              re_index = /\[(\d+)\]/i
              match = re_index.match(str)
              if match
                index = $1
                code_regex = /.*[^\[\d+\]]/i
                translation_code = code_regex.match(str)
                # puts "translation_code = #{translation_code}"
                translation_array = I18n.t(translation_code.to_s.downcase, interpolation)
                # puts "translation_array = #{translation_array}"
                if translation_array.is_a? Array
                  # puts "translation array element = #{translation_array[index.to_i]}"
                  return translation_array[index.to_i]
                else
                  raise "#{str} - array indexing with translation failed, check your translation logic bitxh"
                end
              
              end

              trans = I18n.t(str, interpolation)

              if trans.include? 'translation missing'
                notify_admins(trans, '')
              end

              return trans.is_a?(Array) ? trans[@script_day - 1] : trans
          end # translate

          m = fb_object[:message]

          if !m.nil?

              if is_txt?(m) # just a text message... 
                # default
                trans_code = m[:text]
                next_day = nil
                # 
                # Translate the weekday here. do it, why don't you?
                # if it matches a day of the week thing
                window_text_regex = /scripts.outro.__poc__(\[\d+\])/i
                # window_text_regex = /scripts.outro.(\[\d+\])/i
                if window_text_regex.match(m[:text])
                  # get the code thing to transfer over
                  bracket_index = $1.to_s
                  just_the_text_regex = /.*[^\[\d+\]]/i
                  just_the_text = just_the_text_regex.match(m[:text]).to_s
                  # ok, so now we have the bracket and the text
                  # so now we want to get this_week or next_week

                  # first, grab their current day of the week
                  
                  sw = ScheduleWorker.new
                  schedule = sw.get_schedule(@script_day)

                  # what is our current day?
                  # current_date = sw.get_local_time(Time.now.utc, user.tz_offset)
                  # current_weekday = current_date.wday
                  current_weekday = sw.get_local_day(Time.now.utc, user)

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

                  trans_code = just_the_text + week + bracket_index
                  
                end # window_text_regex.match

                # for intros and teacher/school messaging
                trans_code = teacher_school_messaging(trans_code, recipient)
                # puts "trans_code after = #{trans_code}"

                m[:text] = name_codes( translate.call(trans_code), recipient, next_day)
                # puts m[:text]
              end

              if is_txt_button?(m) # a button with text on it
                # do the next day of the week outro message here

                m[:attachment][:payload][:text] = name_codes translate.call( m[:attachment][:payload][:text] ), recipient
                buttons = m[:attachment][:payload][:buttons]

                buttons.each_with_index do |val, i|
                  buttons[i][:title] = translate.call( buttons[i][:title] )
                end

              end

              if is_story_button?(m) # a story button, with text and pictures
                elements = m[:attachment][:payload][:elements]
                elements.each_with_index do |val, i|
                  elements[i][:title] = name_codes translate.call(elements[i][:title]), recipient
                  # now, substitute story_name by getting story_name from curriculum
                  version = get_curriculum_version(recipient)
                  curriculum = Birdv::DSL::Curricula.get_version(version.to_i)
                  title = curriculum[@script_day - 1][1] # title is at index 1 for curriculum rows
                  elements[i][:image_url] = translate.call(elements[i][:image_url], {story_name: title})
                  # elements[i][:subtitle] = name_codes translate.call(elements[i][:subtitle]), recipient
                  if elements[i][:buttons]
                    buttons = elements[i][:buttons]
                    buttons.each_with_index do |val, i|
                      buttons[i][:title] = translate.call(buttons[i][:title])
                    end
                  end
                end
              end

              # if m[:attachment][:payload][:elements][:title] # a story button, with text and pictures
              #   elements = m[:attachment][:payload][:elements]
              #   translate.call()
              # end

          end

      end

      # the type parameter is useless here
      def send(fb_id, to_send)
        # if lambda, run it! e.g. send(story(args)) 
          if is_story?(to_send)
            to_send.call(fb_id)
            
          # else, we're dealing with a hash! e.g send(text("stuff"))
          elsif to_send.is_a? Hash
            # gotta get the job done gotta start a new nation gotta meet my son
            # do name_codes or process_txt for every type of object that could come through here.....
            # 
            usr = User.where(fb_id: fb_id).first
            fb_object = Marshal.load(Marshal.dump(to_send))

            if usr then
              process_txt(fb_object, usr)
            end

            puts "sending #{fb_object.inspect} to #{fb_id}"
            puts fb_send_json_to_user(fb_id, fb_object)
          end
      end # send_helper


    end # module FB
  end # module DSL
end # module Birdv