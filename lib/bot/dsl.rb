require_relative '../helpers/fb'
module Birdv
  module DSL

    class ScriptClient
      @@scripts = {}

      def self.newscript(script_name, &block)
        puts "adding #{script_name} to thing"
        @@scripts[script_name] = StoryTimeScript.new(script_name, &block)
      end

      def self.scripts
        @@scripts
      end
    end
  end
end

# so this def merits examples. e.g.:
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

module Birdv
  module DSL
    class StoryTimeScript
      include Facebook::Messenger::Helpers 
      attr_reader :script_name, :script_day
      STORY_BASE_URL = 'https://s3.amazonaws.com/st-messenger/'

      def initialize(script_name, &block)
        @fb_objects  = {}
        @sequences   = {}
        @script_name = script_name # TODO how do we wanna do this?
        day          = script_name.scan(/\d+/)[0]
        @script_day = !day.nil? ? day.to_i : 0
        instance_eval(&block)
        return self
      end

      def register_fb_object(obj_key, fb_obj)
        puts 'WARNING: overwriting object #{obj_key.to_s}' if @fb_objects.key?(obj_key.to_sym)
        @fb_objects[obj_key.to_sym] =  fb_obj
      end

      def register_sequence(sqnce_name, block)
        puts 'WARNING: overwriting object #{sqnce_name}' if @fb_objects.key?(sqnce_name.to_sym)
        if @sequences[:init] == nil
          @sequences[:init] = block
        end
        @sequences[sqnce_name.to_sym] = block
      end

      def assert_keys(keys = [], args)
        keys.each{|x| if  !args.key?(x) then raise ArgumentError.new("DSL: need to set :#{x} field") end}
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
      
      def sequence(sqnce_name, &block)
        register_sequence(sqnce_name, block)
      end

      def run_sequence(recipient, sqnce_name)
        # puts(@sequences[sqnce_name.to_sym])
        begin
          instance_exec(recipient, &@sequences[sqnce_name.to_sym])
         # puts "successfully ran #{sqnce_name}!"
        rescue Exception => e  
          puts "#{sqnce_name} failed!"
          puts e.message  
          puts e.backtrace.join("\n") 
        end
      end

      def button(btn_name)
        if btn_name.is_a? String
          return @fb_objects[btn_name.to_sym]
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

      def story(args = {})
        assert_keys([:library, :title, :num_pages], args)
        library     = args[:library]
        title       = args[:title]
        num_pages   = args[:num_pages]
        base = STORY_BASE_URL
        return lambda do |recipient|
          num_pages.times do |i|
            url = "#{base}#{library}/#{title}/#{title}#{i+1}.jpg"
            fb_send_json_to_user(recipient, picture(url:url))
          end
        end
      end


      def send( recipient, to_send,  delay=0 )
        
        # if lambda, run it! e.g. send(story(args)) 
        if to_send.is_a? Proc
          to_send.call(recipient)

        # else, we're dealing with a hash! e.g send(text("stuff"))
        else
          # alter text to include teacher/parent/child names... 
          if to_send[:message][:text]
            to_send[:message][:text] = name_codes(to_send[:message][:text], recipient)
          elsif to_send[:message][:attachment][:payload][:text]
            to_send[:message][:attachment][:payload][:text] = name_codes(to_send[:message][:attachment][:payload][:text], recipient)
          end
              
          puts "sending to #{recipient}"
          puts fb_send_json_to_user(recipient, to_send)
        end
        
        sleep delay if delay > 0
      end

    end
  end
end