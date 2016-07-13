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


      def send( recipient, to_send,  delay=0 )
        
        # if lambda, run it! e.g. send(story(args)) 
        if to_send.is_a? Proc
          to_send.call(recipient)

        # else, we're dealing with a hash! e.g send(text("stuff"))
        elsif to_send.is_a? Hash
          msg = to_send[:message]
          if !msg.nil?
            # alter text to include teacher/parent/child names... 
            if msg[:text]
              msg[:text] = name_codes(msg[:text], recipient)
            elsif msg[:attachment][:payload][:text]
              msg[:attachment][:payload][:text] = name_codes(msg[:attachment][:payload][:text], recipient)
            end
          end
              
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
