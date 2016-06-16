require_relative 'fb_helpers'

module Birdv
  module DSL
    class StoryTimeScript
      include Facebook::Messenger::Helpers 

      attr_reader :script_name

      def initialize(script_name, &block)
        @fb_objects  = {}
        @sequences   = {}
        @script_name = script_name
        # fb_send_txt( { id: '10209571935726081'}, 'hey dude')
      end
      
      def register_fb_object(obj_key, fb_obj)
        puts 'WARNING: overwriting object #{obj_key.to_s}' if @fb_objects.key?(obj_key.to_sym)
        @fb_objects[obj_key.to_sym] =  fb_obj
      end


      def url_button(title, url)
        return { type: 'web_url', title: title, url: url }
      end

      def postback_button(title, payload)
        return { type: 'postback', title: title, payload: payload }
      end
      
      def button_normal(btn_name, window_txt, btns)
        register_fb_object(
          btn_name,
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
        )
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
      #         }]
      #         }
      #         }
      #         }
      #
      def template_generic(btn_name, elemnts)
        register_fb_object(
          btn_name,
          message: {
            attachment: {
              type: 'template',
              payload: {
                template_type: 'generic',
                elements: elemnts
              }
            }
          }
        )
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
      


      def register_sequence(sqnce_name, &block)
        puts 'WARNING: overwriting object #{sqnce_name}' if @fb_objects.key?(obj_key.to_sym)
        @sequences[sqnce_name.to_sym] = block
      end




      def sequence(sqnce_name, &block)
        register_sequence(sqnce_name, block)
      end



      def run_sequence(recipient, sqnce_name)
        begin
          instance_eval(@sequences[sqnce_name.to_sym])
          puts "successfully ran #{sqnce_name}!"
        rescue #TODO: put in the error stuff david halp!!!
          puts "#{sqnce_name} failed!"
        end
      end

      def button(btn_name)
      	return @fb_objects[btn_name.to_sym]
      end

      def text(txt)
      	return message: {text: txt}
      end

      def picture(img_url)
      	return message: {
		             attachment: {
		               type: 'image',
		               payload: {
		                 url: img_url
		               }
		             }
		           }
      end

      def story(recipient, libary, url_title, num_pages)
      	STORY_BASE_URL = 'https://s3.amazonaws.com/st-messenger/'
      	num_pages.times do |i|
      		img_url = STORY_BASE_URL+"#{library}/#{title_url}/#{title_url}#{i+1}.jpg"
      		fb_send_json_to_user(recipient, picture(img_url))
      	end
      	sleep delay if delay > 0
      end

      def send(some_json, recipient, delay=0)
      	fb_send_json_to_user(recipient, some_json)
      	sleep delay if delay > 0
      end

    end
  end
end
