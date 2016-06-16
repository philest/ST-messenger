require_relative 'fb_helpers'

class FBObject

  def send(recipient)

  end
end


class FBButton


end
class FBTemplateButton
  
  attr_reader :title, :buttons
  def initialize()
    @buttons = []
  end

  def setButtons

end

class FBTemplateGeneric


module Birdv
  module DSL
    class StoryTimeScript
      include Facebook::Messenger::Helpers 
      attr_reader :script_name

      def initialize(script_name, &block)
	@fb_objects = {}
	@script_name = script_name
	# fb_send_txt( { id: '10209571935726081'}, 'hey dude')
      end
      
      def register_fb_object(obj_key)
	puts 'WARNING: overwriting object #{obj_key.to_s}' if @fb_objects.key?(obj_key)
	@fb_objects << fb_obj
      end


      def url_button(title, url)
	return { type: 'web_url', title: title, url: url }
      end

      def postback_button(title, payload)
	return { type: 'postback', title: title, payload: payload }
      end
      
      def normal_button(btn_name, window_txt, btns)
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

      def generic_button(
      def story_button(btn_name, title, subtitle='', img_url, btns)

      end
    end
  end
end

#include Birdv::DSL


