module Birdv
  module DSL
    module FB

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


      def name_codes(str, fb_id)
        user = User.where(:fb_id => fb_id).first

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
          str = str.gsub(/__SCHOOL__/, 'StoryTime')
          str = str.gsub(/__CHILD__/, 'your child')
          return str
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
          puts "sending #{url}!"
          fb_send_json_to_user(recipient, picture(url:url))
        end
      end


       # TODO: should I delete args? not used
      def create_story(args={}, script_day)
        if !args.empty?
          puts "(DSL.send.story) WARNING: you don't need to set any args when sending a story. It doesn't do anything!"
        end
        
        return lambda do |recipient|
          begin

            version = get_curriculum_version(recipient)
            locale  = get_locale(recipient)

            curriculum = Birdv::DSL::Curricula.get_version(version.to_i)

            # needs to be indexed at 0, so subtract 1 from the script day, which begins at 1
            storyinfo = curriculum[script_day - 1]

            lib, title, num_pages = storyinfo

            send_story({
              recipient:  recipient,
              library:    lib,
              title:      title,
              num_pages:  num_pages.to_i,
              locale:     locale
            })
            
            # TODO: error stuff

            # TODO: make this atomic somehow? slash errors
            User.where(fb_id:recipient).first.state_table.update(
                                        last_story_read_time:Time.now.utc, 
                                        last_story_read?: true)

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


      # can we bring this out to the fb module? 
      def process_txt( fb_object, recipient, locale, script_day )
        if locale.nil? then locale = 'en' end
        I18n.locale = locale

        translate = lambda do |str|

          if str.nil? or str.empty? then 
            return str   
          end

          trans = I18n.t str
          return trans.is_a?(Array) ? trans[script_day - 1] : trans
        end

        m = fb_object[:message]

        if !m.nil?
            if is_txt?(m) # just a text message... 

              m[:text] = name_codes translate.call(m[:text]), recipient
            end

            if is_txt_button?(m) # a button with text on it
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
                elements[i][:image_url] = translate.call(elements[i][:image_url])
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
      def send_helper(fb_id, to_send, script_day, type)
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
              process_txt(fb_object, fb_id, usr.locale, script_day) 
            end

            puts "sending to #{fb_id}"
            puts fb_send_json_to_user(fb_id, fb_object)
          end
      end # send_helper





    end # module FB
  end # module DSL
end # module Birdv