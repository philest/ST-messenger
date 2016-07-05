require 'httparty'
phone_number = "+1(818)689-7323"
access_token = "EAAYOZCTY8IiwBAIZCkoKlZAHtpFcxBqHUKFUsNZCDUIcxVDWJqhiqdB4q0jDpaiubiYmRtZBBFjCMWE6jnoBoT6qAc2Tr1VtOl4L6RvJFKVFUScqavZByWsBROo1FGVSpcpsjKyFc4HtkjocuVAgcM3ITJPGxBNOndaRA7HFrhqQZDZD"

response = HTTParty.post(
	"https://graph.facebook.com/v2.6/me/messages",
	query: {
		access_token: access_token
	},
	body: {
		recipient: {
			phone_number: phone_number
		},
		message: {
			text: "hello, world!"
		}
	}

)

puts response.inspect