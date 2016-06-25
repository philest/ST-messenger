require 'httparty'
module Facebook
  module Messenger
    module Helpers
      GRAPH_URL = "https://graph.facebook.com/v2.6/me/messages"

      def get_graph_url
        GRAPH_URL
      end

      def self.get_graph_url
        GRAPH_URL
      end

      def deliver(message)
        HTTParty.post(GRAPH_URL, 
          query: {access_token: ENV['FB_ACCESS_TKN']},
            :body => message.to_json,
            :headers => { 'Content-Type' => 'application/json' } 
          )
      end

      def fb_send_txt(recipient, message)
       


        deliver(
          recipient: recipient, 
          message: {
            text: message
          }
        )
      end


      def fb_send_pic(recipient, img_url)
        deliver(
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
        deliver(
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
          fb_name = JSON.parse HTTParty.get("https://graph.facebook.com/v2.6/#{id['id']}?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}").body
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
        deliver( 
          recipient: { id: user_id }, 
          message: msg_json[:message] 
          )
      end

      def http_send_json_to_user(user_id, msg_json)
        HTTParty.post(GRAPH_URL, 
          query: {access_token: ENV['FB_ACCESS_TKN']},
            :body => { 
              recipient: user_id,
              message: msg_json[:message]
            }.to_json,
            :headers => { 'Content-Type' => 'application/json' } 
          )
      end


      # send arbitrary json!
      def fb_send_arbitrary(arb)
        deliver(arb)
      end
    end
  end
end
