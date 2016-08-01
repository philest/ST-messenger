require 'httparty'
require 'active_support/time'
module Facebook
  module Messenger
    module Helpers
      GRAPH_URL = "https://graph.facebook.com/v2.6/me/messages"
      
      SMS_WAIT = 10.seconds
      MMS_WAIT = 20.seconds

      def get_graph_url
        GRAPH_URL
      end

      def self.get_graph_url
        GRAPH_URL
      end

      def name_codes(str, id)
        user = User.where(:fb_id => id).first
        parent  = user.first_name
        child   = user.child_name.nil? ? "your child" : user.child_name.split[0]
        teacher = user.teacher.nil? ? "StoryTime" : user.teacher.signature        
        str = str.gsub(/__TEACHER__/, teacher)
        str = str.gsub(/__PARENT__/, parent)
        str = str.gsub(/__CHILD__/, child)
        return str
      end


      def deliver(message)
        HTTParty.post(GRAPH_URL, 
          query: {access_token: ENV['FB_ACCESS_TKN']},
            :body => message.to_json,
            :headers => { 'Content-Type' => 'application/json' } 
          )
      end

      def fb_send_txt(recipient, message)

        message = name_codes(message, recipient['id'])

        deliver(
          recipient: recipient, 
          message: {
            text: message
          }
        )
      end

      def process_locale(locale)
        if locale.nil? or locale.empty? 
          return 'en'
        end

        l = locale.split('_').first
        # If user has a language other than English or Spanish, default to English. 
        # We'll add more languages later. 
        if ['en', 'es'].include? l and not l.nil? and not l.empty?
          return l
        else 
          return 'en'
        end
      rescue => e
        p e.message + " something went wrong with processing the user's locale..."
        return 'en'
      end


      def register_user(recipient)
        # Save user in the database.
        # TODO : update an existing DB entry to coincide the fb_id with phone_number
        fields = "first_name,last_name,profile_pic,locale,timezone,gender"
        data = JSON.parse HTTParty.get("https://graph.facebook.com/v2.6/#{recipient['id']}?fields=#{fields}&access_token=#{ENV['FB_ACCESS_TKN']}").body
        name = data['first_name'] + " " + data["last_name"]
      rescue => e
        User.create(:fb_id => recipient["id"], platform: 'fb')
        p e.message + ": created user w/o an associated child or phone number"
      else
        puts "successfully found user data for #{name}"
        last_name = data['last_name']
        child_match = /[a-zA-Z]*( )?#{last_name}/i  # if child's last name matches, go for it
        begin
          candidates = User.where(:child_name => child_match, :fb_id => nil)
          if candidates.all.empty? # add a new user w/o child info (no matches)
            User.create(:fb_id => recipient['id'], platform: 'fb', first_name: data['first_name'], last_name: data['last_name'], :gender => data['gender'], :locale => process_locale(data['locale']), :profile_pic => data['profile_pic'])
          else
            # implement stupid fb_name matching to existing user matching
            candidates.order(:enrolled_on).first.update(:fb_id => recipient['id'], first_name: data['first_name'], last_name: data['last_name'], :gender => data['gender'], :locale => process_locale(data['locale']), :profile_pic => data['profile_pic'])
          end
        rescue Sequel::Error => e
          p e.message + " did not insert, already exists in db"
        end # rescue - db transaction
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
          fb_name = JSON.parse HTTParty.get("https://graph.facebook.com/v2.6/#{id}?fields=first_name,last_name,gender&access_token=#{ENV['FB_ACCESS_TKN']}").body
          return fb_name
        rescue HTTParty::Error
          name = ""
        end
      end


      def fb_get_name_honorific(id)
        fb_name = fb_get_user(id)
        if fb_name['last_name']== ''
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

      def normalize_tz(timezone, *times)
        user_tz = ActiveSupport::TimeZone.new(timezone)
        times.map do |time|
          time.utc.in_time_zone(user_tz)
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
