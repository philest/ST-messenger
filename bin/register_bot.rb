require './ENV_LOCAL'
require 'httparty'

response = HTTParty.post(
	"https://graph.facebook.com/v2.6/me/subscribed_apps",
	query: {
		access_token: FB_ACCESS_TKN
	}
)
puts response.inspect
