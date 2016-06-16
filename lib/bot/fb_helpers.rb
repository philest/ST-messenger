
module Facebook
  module Messenger
    module Helpers

      def fb_send_txt(recipient, message)
        Bot.deliver(
          recipient: recipient, 
          message: {
            text: message
          }
        )
      end


      def fb_send_pic(recipient, img_url)
        Bot.deliver(
          recipient: recipient,
          message: {
            attachment: {
              type: 'image',
              payload: {
                url: img_url
              }
            }
          }
        )
      end


      # TODO: make btns optional
      def fb_send_template_generic(recipient, title, img_url, btns)
        Bot.deliver(
          recipient: recipient,
          message: {
            attachment: {
              type:'template',
              payload:{
                template_type: 'generic',
                elements: [
                  {   
                    title: title,
                    image_url: img_url,
                    buttons: btns
                  }
                ]
              }
            }
          }
        )
      end


      def fb_get_user(id)
        begin
          fb_name = HTTParty.get("https://graph.facebook.com/v2.6/#{id['id']}?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}")
        rescue HTTParty::Error
          name = ""
        end
      end


      def fb_get_name_honorific(id)
        fb_name = fb_get_user(id)
        if fb_name['name']== ''
          return ""
        else
          honorific = "Mx."
          case fb_name['gender']
          when 'male'
            honorific = "Mr."
          when 'female'
            honorific = "Ms."
          end
          return "#{honorific} #{fb_name['last_name']}"
        end
      end


      def fb_send_json_to_user(user_id, msg_json)
        Bot.deliver({ recipient: { id: user_id }, msg_json })
      end

      # send arbitrary json!
      def fb_send_arbitrary(arb)
        Bot.deliver(arb)
      end
    end
  end
end
