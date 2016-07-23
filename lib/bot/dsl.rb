require_relative '../helpers/fb'
require_relative '../helpers/contact_helpers'
require_relative '../workers/bot_worker'
# the translation files
require_relative '../../config/initializers/locale' 

module Birdv
  module DSL
    class ScriptClient
      @@scripts = {
        'sms' => {},
        'mms' => {},
        'fb'  => {}
      }

      def self.new_script(script_name, platform='fb', &block)
        puts "adding #{script_name} - platform #{platform} to thing"
        @@scripts[platform][script_name] = StoryTimeScript.new(script_name, platform, &block)
      end

      def self.scripts
        @@scripts
      end

      def sms_scripts 
        @@scripts['sms']
      end

      def mms_scripts 
        @@scripts['mms']
      end

      def self.fb_scripts
        @@scripts['fb']
      end

      def self.clear_scripts
        @@scripts = {}
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
      STORY_BASE_URL = 'http://d2p8iyobf0557z.cloudfront.net/'

      def initialize(script_name, platform, &block)
        @fb_objects  = {}
        @sequences   = {}
        @script_name = script_name # TODO how do we wanna do this?
        @platform = platform
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

      def sequence_seen? (sqnce_to_send_name, last_sequence_seen)

        if (last_sequence_seen.nil?)
          return false
        end

        sqnce_new = @sequences[sqnce_to_send_name.to_sym] # TODO: ensure non-sym input is ok
        sqnce_old = @sequences[last_sequence_seen.to_sym]

        # TODO: write spec that ensure nothing bad happens when bade sqnce name given
        if (sqnce_new != nil && sqnce_old != nil)
          if sqnce_new[1] > sqnce_old[1]
            return false
          end
        end

        # assume that we have seen the sqnce already
        return true
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
        # if fb_id didn't work, maybe we're on the wrong platform
        if user.nil?
          user = User.where(phone: id).first
        end

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

      def sequence(sqnce_name, &block)
        register_sequence(sqnce_name, block)
      end

      def run_sequence(recipient, sqnce_name)
        begin
          ret =  instance_exec(recipient, &@sequences[sqnce_name.to_sym][0])          

          u = User.where(fb_id:recipient).first
          if u.nil?
            u = User.where(phone:recipient).first
          end

          u.state_table.update(last_sequence_seen: sqnce_name.to_s)
          return ret

        rescue => e  
          puts "#{sqnce_name} from script #{@script_name} failed!"
          puts "the known sequences are: #{@sequences}"
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
        BotWorker.perform_in(time_delay, recipient, @script_name, sequence_name, platform=@platform)
      end


      def send_story(args = {})
        assert_keys([:library, :title, :num_pages, :recipient, :locale], args)
        library     = args[:library]
        title       = args[:title]
        num_pages   = args[:num_pages]
        recipient   = args[:recipient]
        locale      = args[:locale]
        base = STORY_BASE_URL
        puts "the number of pages #{num_pages}"
        locale_url_seg = (locale == 'es') ? 'es/' : ''
        puts "locale_url_seg = #{locale_url_seg}"

        num_pages.times do |i|
          url = "#{base}#{library}/#{locale_url_seg}#{title}/#{title}#{i+1}.jpg"
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
            locale  = get_locale(recipient)

            curriculum = Birdv::DSL::Curricula.get_version(version.to_i)

            # needs to be indexed at 0, so subtract 1 from the script day, which begins at 1
            storyinfo = curriculum[@script_day - 1]

            lib, title, num_pages = storyinfo

            send_story({
              recipient:  recipient,
              library:    lib,
              title:      title,
              num_pages:  num_pages.to_i,
              locale:     locale
            })
            
            # TODO: error stuff

            puts 'SHOULD BE HERE'
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
        if thing[:text].nil? then false else true end
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


      def process_txt( fb_object, recipient, locale )
        if locale.nil? then locale = 'en' end
        I18n.locale = locale

        translate = lambda do |str|

          if str.nil? or str.empty? then 
            return str   
          end

          trans = I18n.t str
          return trans.is_a?(Array) ? trans[@script_day - 1] : trans
        end

        m = fb_object[:message]

        puts "message = #{m}"
        if !m.nil?
            if is_txt?(m) # just a text message... 
              puts "text: " + m[:text]
              m[:text] = name_codes translate.call(m[:text]), recipient
            end

            if is_txt_button?(m) # a button with text on it
              puts "txt_button txt: " + m[:attachment][:payload][:text].to_s
              m[:attachment][:payload][:text] = name_codes translate.call( m[:attachment][:payload][:text] ), recipient
              buttons = m[:attachment][:payload][:buttons]

              buttons.each_with_index do |val, i|
                puts "txt button title txt: #{buttons[i][:title]}"
                buttons[i][:title] = translate.call( buttons[i][:title] )
              end

            end

            if is_story_button?(m) # a story button, with text and pictures
              puts "story_button txt: " + m[:attachment][:payload][:elements].to_s

              elements = m[:attachment][:payload][:elements]
              elements.each_with_index do |val, i|
                elements[i][:title] = name_codes translate.call(elements[i][:title]), recipient
                elements[i][:image_url] = translate.call(elements[i][:image_url])
                # elements[i][:subtitle] = name_codes translate.call(elements[i][:subtitle]), recipient
                if elements[i][:buttons]
                  buttons = elements[i][:buttons]
                  buttons.each_with_index do |val, i|
                    puts "story button title txt: #{buttons[i][:title]}"
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

      def translate_sms(phone, text)
        usr = User.where(phone: phone).first
        I18n.locale = usr.locale

        if text.nil? or text.empty? then 
          return text   
        end

        trans = I18n.t text
        if trans.is_a? Array
          return name_codes trans[@script_day - 1], phone 
        else
          return names_codes trans, phone
        end

      rescue NoMethodError => e
        p e.message + " usr doesn't exist, can't translate"
        return false
      end

      def send_sms( phone, text )
        text = translate_sms( phone, text )
        if text == false
          puts "something went wrong, can't translate this text (likely, the phone # doesn't belong to a user in the system)"
          return
        end
        HTTParty.post(
          "https://st-enroll.herokuapp.com/txt", 
          body: {
            recipient: phone
            text: text
          }
        )
      end

      def send_mms( phone, img_url )
        HTTParty.post(
          "https://st-enroll.herokuapp.com/mms", 
          body: {
            recipient: phone
            img_url: img_url
          }
        )
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
          fb_object = Marshal.load(Marshal.dump(to_send))

          if usr then 
            process_txt(fb_object, recipient, usr.locale) 
          end

          puts "processed:\n#{fb_object}"
          puts "sending to #{recipient}"
          puts fb_send_json_to_user(recipient, fb_object)
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
