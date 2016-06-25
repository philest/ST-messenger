require_relative '../helpers/fb'

module Birdv
  module DSL
    class StoryTimeScript
      include Facebook::Messenger::Helpers 
      @@scripts = {}

      attr_reader :script_name, :script_day
      STORY_BASE_URL = 'https://s3.amazonaws.com/st-messenger/'

      def initialize(script_name, &block)
        @fb_objects  = {}
        @sequences   = {}
        @script_name = script_name # TODO how do we wanna do this?
        day          = script_name.scan(/\d+/)[0]
        if !day.nil?
          @script_day = day.to_i
        else
          @script_day = 0
        end
        instance_eval(&block)
        puts "adding #{@script_name} to thing"
        @@scripts[script_name] = self
        # fb_send_txt( { id: '10209571935726081'}, 'hey dude')
      end

      def self.scripts
        @@scripts
      end
      
      def register_fb_object(obj_key, fb_obj)
        puts 'WARNING: overwriting object #{obj_key.to_s}' if @fb_objects.key?(obj_key.to_sym)
        @fb_objects[obj_key.to_sym] =  fb_obj
      end


      def url_button(title, url)
        return { type: 'web_url', title: title, url: url }
      end

      def script_payload(sequence_name)
        puts "cool payload: #{@script_name.to_s}_#{sequence_name.to_s}"

        return "#{@script_name.to_s}_#{sequence_name.to_s}"
      end

      def postback_button(title, payload)
        return { type: 'postback', title: title, payload: payload.to_s}
      end

      def name_codes(str, id)
        user = User.where(:fb_id => id).first
        parent  = user.name.split[0]
        child   = user.child_name.nil? ? "your child" : user.child_name.split[0]
        teacher = user.teacher.nil? ? "StoryTime" : user.teacher.signature        
        str = str.gsub(/__TEACHER__/, teacher)
        str = str.gsub(/__PARENT__/, parent)
        str = str.gsub(/__CHILD__/, child)

        return str
      end

      def button_normal(btn_name, window_txt, btns)
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
        register_fb_object(btn_name,tjson)
        return tjson
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
      #
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
                  


      def story_button(btn_name, title, subtitle='', img_url, btns)
        elmnts = {title: title, image_url: img_url, subtitle:subtitle}
        # TODO: add more exceptions? e.g. when no img supplied?
        if !btns.empty?
          elmnts[:buttons]=btns
        else
          puts "WARNING: no buttons in yo' story_button"
        end
        template_generic(btn_name, [elmnts])
      end
      


      def register_sequence(sqnce_name, block)
        puts 'WARNING: overwriting object #{sqnce_name}' if @fb_objects.key?(sqnce_name.to_sym)
        if @sequences[:init] == nil
          @sequences[:init] = block
        end
        @sequences[sqnce_name.to_sym] = block

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
        return @fb_objects[btn_name.to_sym]
      end

      def text(txt)
        return {message: {text: txt}}
      end

      def picture(img_url)
        return {message: {
                 attachment: {
                   type: 'image',
                   payload: {
                     url: img_url
                   }
                 }
               }}
      end

      def send_story(library, url_title, num_pages, recipient, delay=0)
        num_pages.times do |i|
          img_url = STORY_BASE_URL+"#{library}/#{url_title}/#{url_title}#{i+1}.jpg"
          fb_send_json_to_user(recipient, picture(img_url))
        end
        sleep delay if delay > 0
      end

      def send(some_json, recipient, delay=0)
        # alter text to include teacher/parent/child names... 
        if some_json[:message][:text]
          # TODO check to see if id key is a symbol or a string.............
          some_json[:message][:text] = name_codes(some_json[:message][:text], recipient)
        elsif some_json[:message][:attachment][:payload][:text]
          some_json[:message][:attachment][:payload][:text] = name_codes(some_json[:message][:attachment][:payload][:text], recipient)
        end
            
        puts "sending to #{recipient}"
        puts fb_send_json_to_user(recipient, some_json)
        sleep delay if delay > 0
      end
    end
  end
end




