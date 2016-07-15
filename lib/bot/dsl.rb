require_relative '../helpers/fb'
require_relative '../helpers/contact_helpers'
require_relative '../workers/bot_worker'

module Birdv
  module DSL
    class ScriptClient
      @@scripts = {}

      def self.new_script(script_name, &block)
        puts "adding #{script_name} to thing"
        @@scripts[script_name] = StoryTimeScript.new(script_name, &block)
      end

      def self.scripts
        @@scripts
      end

    end
  end
end


module Birdv
  module DSL
    class StoryTimeScript
      include Facebook::Messenger::Helpers 
      include ContactHelpers

      attr_reader :script_name, :script_day, :num_sequences, :sequences
      STORY_BASE_URL = 'https://s3.amazonaws.com/st-messenger/'

      def initialize(script_name, &block)
        @fb_objects  = {}
        @sequences   = {}
        @script_name = script_name # TODO how do we wanna do this?
        @num_sequences = 0
        day          = script_name.scan(/\d+/)[0]
        
        # TODO: something about this
        @script_day = !day.nil? ? day.to_i : 0


        instance_eval(&block)
        return self
      end

      def register_fb_object(obj_key, fb_obj)
        puts 'WARNING: overwriting object #{obj_key.to_s}' if @fb_objects.key?(obj_key.to_sym)
        @fb_objects[obj_key.to_sym] =  fb_obj
      end


      def register_sequence(sqnce_name, block)
        sqnce = sqnce_name.to_sym

        # check if this sqnce was already registered
        already_registered = @sequences.has_key?(sqnce)

        # register sqnce and index it
        @sequences[sqnce]  = [block, @num_sequences]

        if @sequences[:init] == nil
          @sequences[:init] = @sequences[sqnce]
        end

        # if sqnce wasn't previously registered, increment the number of registered sequences
        warning = 'WARNING: you already registered that sequence :('
        already_registered ? puts(warning) : @num_sequences = @num_sequences+1 
      end

      def assert_keys(keys = [], args)
        keys.each{|x| if  !args.key?(x) then raise ArgumentError.new("DSL: need to set :#{x} field") end}
      end


      def day(number)
        @script_day = number
      end


      def url_button(title, url)
        return { type: 'web_url', title: title, url: url }
      end

      def script_payload(sequence_name)
        puts "cool payload: #{@script_name.to_s}_#{sequence_name.to_s}"
        return "#{@script_name.to_s}_#{sequence_name.to_s}"
      end

      def postback_button(title, payload)
        return { type: 'postback', title: title, payload: payload.to_s }
      end


      def name_codes(str, id)
        user = User.where(:fb_id => id).first
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

      def sequence(sqnce_name, &block)
        register_sequence(sqnce_name, block)
      end

      def run_sequence(recipient, sqnce_name)
        # puts(@sequences[sqnce_name.to_sym])
        begin
          ret =  instance_exec(recipient, &@sequences[sqnce_name.to_sym][0])          
          User.where(fb_id:recipient).first.state_table.update(last_sequence_seen: sqnce_name.to_s)
          return ret

         # puts "successfully ran #{sqnce_name}!"
        rescue => e  
          puts "#{sqnce_name} from script #{@script_name} failed!"
          puts e.message  
          puts e.backtrace.join("\n") 
          email_admins("StoryTime Script error: #{sqnce_name} failed!", e.backtrace.join("\n"))
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

      def delay(recipient, sequence_name, time_delay)
        BotWorker.perform_in(time_delay, recipient, @script_name, sequence_name)
      end


      def send_story(args = {})
        assert_keys([:library, :title, :num_pages, :recipient], args)
        library     = args[:library]
        title       = args[:title]
        num_pages   = args[:num_pages]
        recipient   = args[:recipient]
        base = STORY_BASE_URL
        puts "the number of pages #{num_pages}"
        num_pages.times do |i|
          url = "#{base}#{library}/#{title}/#{title}#{i+1}.jpg"
          puts "sending #{url}!"
          fb_send_json_to_user(recipient, picture(url:url))
        end
      end


      # TODO: should I delete args? not used
      def story(args={})
        if !args.empty?
          puts "(DSL.send.story) WARNING: you don't need to set any args when sending a story. It doesn't do anything!"
        end
        
        return lambda do |recipient|
          begin

            version = get_curriculum_version(recipient)

            puts "THE CURRICULUM VERSION WE GETTING IS #{version}"
            curriculum = Birdv::DSL::Curricula.get_version(version.to_i)
   
            # needs to be indexed at 0, so subtract 1 from the script day, which begins at 1
            storyinfo = curriculum[@script_day - 1]

            lib, title, num_pages = storyinfo
            puts "#{lib} #{num_pages}"

            send_story({
              recipient:  recipient,
              library:    lib,
              title:      title,
              num_pages:  num_pages.to_i
            })
            
            # TODO: error stuff

            # TODO: make this atomic somehow? slash errors
            User.where(fb_id:recipient).first.state_table.update(last_story_read_time:Time.now.utc, 
                                 last_story_read?: true, 
                                 story_number: Sequel.+(:story_number, 1))

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
        p e.message
        return false
      end

      def is_story_button?(thing)
        if thing[:attachment][:payload][:elements].nil? then false else true end
      rescue NoMethodError => e
        p e.message
        return false
      end

      def is_txt?(thing)
        if thing[:text].nil? then 
          puts "it's not text!"
          return false 
        else 
          puts "it's text!"
          return true 
        end
      rescue NoMethodError => e
        p e.message
        return false
      end

      def is_img?(thing)
        if [:attachment][:type] == 'image' then true else false end
      rescue NoMethodError => e
        p e.message
        return false
      end

      def is_story?(thing)
        if thing.is_a? Proc then true else false end
      rescue NoMethodError => e
        p e.message
        return false
      end

      def process_txt( msg, recipient, locale, story_number )
        if locale.nil? then locale = 'en' end
        I18n.locale = locale

        puts "translated shit\n" + I18n.t('scripts.teacher_intro').to_s

        translate = lambda do |str|
          puts "before translation: " + str.to_s
          puts "after: " + I18n.t(str).to_s

          if str.nil? or str.empty? then 
            return str   
          end

          trans = I18n.t str
          return trans.is_a?(Array) ? trans[story_number] : trans
        end

        m = msg[:message]
        if !m.nil?
            if is_txt?(m) # just a text message... 
              puts "text: " + m[:text]
              puts "translated: " + I18n.t(m[:text])

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
                # elements[i][:image_url] = translate.call(elements[i][:image_url]), recipient
                # elements[i][:subtitle] = name_codes translate.call(elements[i][:subtitle]), recipient
                # name, image url, title
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
            #   translate()
            # end

        end

      end


      def send( recipient, to_send,  delay=0 )
        
        # if lambda, run it! e.g. send(story(args)) 
        if is_story?(to_send)
          to_send.call(recipient)

        # else, we're dealing with a hash! e.g send(text("stuff"))
        elsif to_send.is_a? Hash
          # gotta get the job done gotta start a new nation gotta meet my son
          # do name_codes or process_txt for every type of object that could come through here.....
          # 

          puts "before processing:\n#{to_send}"

          usr = User.where(fb_id: recipient).first
          if usr then process_txt(to_send, recipient, usr.locale, 0) end

          puts "processed:\n#{to_send}"
          puts "sending to #{recipient}"
          puts fb_send_json_to_user(recipient, to_send)
        end
        
        # TODO: something about this next line
        #sleep delay if delay > 0
      end

    end
  end
end


# valid generic template format
# message: {
#   attachment: {
#     type: 'template',
#     payload: {
#       template_type: 'generic',
#       elements: [{
#         title: title,
#         image_url: 'image_url is an optional field, but only include if you will use it',
#         subtitle: "you can acutally include subititle but still set it as empty string",
#         buttons: [{you are require to add buttons}]
#       }]
#     }
#   }
# }
