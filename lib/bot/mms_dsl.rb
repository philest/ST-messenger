module Birdv

  module DSL

    module MMS

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

          str = str.gsub(/__TEACHER__/, teacher)
          str = str.gsub(/__PARENT__/, parent)
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




    end # module MMS

  end # module DSL

end # module Birdv