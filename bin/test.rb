require 'dotenv'
Dotenv.load
require 'httparty'
require 'openssl'
require_relative '../lib/helpers/fb'

def generate_hmac(content)
  OpenSSL::HMAC.hexdigest('sha1'.freeze, app_secret, content)
end

puts "fuck"

s = Facebook::Messenger::Helpers


# b = s.button_normal('test', "this is a fucking test", s.postback_button('thanks', 'asshole'))
# s.fb_send_json_to_user("1042751019139427", b)



response = HTTParty.post(
	"https://graph.facebook.com/me/messages",
	query: {
		access_token: ENV['RACK_ENV'] == 'production' ? ENV['PRODUCTION_FB_ACCESS_TKN'] : ENV['FB_ACCESS_TKN']
		# access_token: "EAAYOZCTY8IiwBAIZCkoKlZAHtpFcxBqHUKFUsNZCDUIcxVDWJqhiqdB4q0jDpaiubiYmRtZBBFjCMWE6jnoBoT6qAc2Tr1VtOl4L6RvJFKVFUScqavZByWsBROo1FGVSpcpsjKyFc4HtkjocuVAgcM3ITJPGxBNOndaRA7HFrhqQZDZD"
	},
	body: {
		recipient: { 
			id: "1042751019139427"
		},
		message: {
			attachment: {
				type: "template",
				payload: {
					template_type: "button",
					text: "Hi, this is StoryTime! We'll see you message soon. To send your text to your teacher, tap.",
					buttons: [
						{
							title: "send to teacher",
							:type => "postback",
							payload: "sent"
						}
					]
				}
			}
		}
	}
)



puts response.inspect

x =  {body: {
		recipient: { 
			id: "1042751019139427"
		},
		message: {
			attachment: {
				type: "template",
				payload: {
					template_type: "button",
					text: "Hi, this is StoryTime! We'll see you message soon. To send your text to your teacher, tap.",
					buttons: [
						{
							title: "send to teacher",
							:type => "postback",
							payload: "sent"
						}
					]
				}
			}
		}
	}}

puts x[:body][:message][:attachment][:payload][:buttons][0][:type]


# response = HTTParty.post(
# 	"https://graph.facebook.com/me/messages",
# 	query: {
# 		access_token: ENV['RACK_ENV'] == 'production' ? ENV['PRODUCTION_FB_ACCESS_TKN'] : ENV['FB_ACCESS_TKN']
# 		# access_token: "EAAYOZCTY8IiwBAIZCkoKlZAHtpFcxBqHUKFUsNZCDUIcxVDWJqhiqdB4q0jDpaiubiYmRtZBBFjCMWE6jnoBoT6qAc2Tr1VtOl4L6RvJFKVFUScqavZByWsBROo1FGVSpcpsjKyFc4HtkjocuVAgcM3ITJPGxBNOndaRA7HFrhqQZDZD"
# 	},
# 	body: {
# 		recipient: { 
# 			id: "1042751019139427"
# 		},
# 		message: {
# 			text: "test"
# 		}
			
# 	}
# )
