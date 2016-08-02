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

      # TODO: write this in an MMS-specific way.
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
          puts "sending #{url}!"


          # THIS IS THE ONLY LINE THAT NEEDS TO CHANGE
          # ADD ASYNC DELAYS AND SHIT
          fb_send_json_to_user(recipient, picture(url:url))
        end
      end


      # TODO: make this MMS-specific
      def create_story(args={}, script_day)
        if !args.empty?
          puts "(DSL.send.story) WARNING: you don't need to set any args when sending a story. It doesn't do anything!"
        end
        
        return lambda do |phone_no|
          begin

            # version = get_curriculum_version(phone_no)
            locale  = get_locale(phone_no)

            # curriculum = Birdv::DSL::Curricula.get_version(version.to_i)

            # needs to be indexed at 0, so subtract 1 from the script day, which begins at 1
            storyinfo = curriculum[script_day - 1]

            lib, title, num_pages = storyinfo

            send_story({
              recipient:  phone_no,
              library:    lib,
              title:      title,
              num_pages:  num_pages.to_i,
              locale:     locale
            })
            
            # TODO: error stuff

            # TODO: make this atomic somehow? slash errors
            User.where(fb_id:phone_no).first.state_table.update(
                                        last_story_read_time:Time.now.utc, 
                                        last_story_read?: true)

          rescue => e
            p e.message + " failed to send user with fb_id #{phone_no} a story"
            raise e
          end         
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


      def send_helper(phone, to_send, script_day, type)
        # create a story() function for mms, which incorporates delays.
        case type
        when 'sms'

          text = translate_sms( phone, to_send )
          if text == false
            puts "something went wrong, can't translate this text (likely, the phone # doesn't belong to a user in the system)"
            return
          end
          HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/txt", 
            body: {
              recipient: phone,
              text: text
          })

        when 'mms'
          HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/mms", 
            body: {
              recipient: phone,
              img_url: to_send
          })
        end
      end # send_helper


    end # module MMS

  end # module DSL

end # module Birdv