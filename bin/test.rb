require 'httparty'
phone_number 	= "+1(818)689-7323"
kimberly		= "+1(832)603-1340"
aubrey			= "+1(301)332-8953"
vasilije 		= "+1(850)524-7304"
donald 			= "+1(314)249-1479"
andrew 			= "+1(919)322-0867"
conor			= "+1(202)489-2363"
steffi 			= "+1(203)599-5978"
quyen			= "+1(815)319-3252"
harry			= "+1(818)456-3162"
access_token 	= "EAAYOZCTY8IiwBAIZCkoKlZAHtpFcxBqHUKFUsNZCDUIcxVDWJqhiqdB4q0jDpaiubiYmRtZBBFjCMWE6jnoBoT6qAc2Tr1VtOl4L6RvJFKVFUScqavZByWsBROo1FGVSpcpsjKyFc4HtkjocuVAgcM3ITJPGxBNOndaRA7HFrhqQZDZD"

response = HTTParty.post(
	"https://graph.facebook.com/v2.6/me/messages",
	query: {
		access_token: access_token
	},
	body: {
		recipient: {
			phone_number: aubrey
		},
		message: {
			text: "hello, world!"
		}
	}

)

puts response.inspect