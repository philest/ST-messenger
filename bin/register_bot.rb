require 'dotenv'
Dotenv.load
# require './ENV_LOCAL'
require 'httparty'
require 'openssl'


def generate_hmac(content)
	OpenSSL::HMAC.hexdigest('sha1'.freeze, "fe1a89acd26f54cc5cebad6b221ad8cd", content)
end



response = HTTParty.post(
	"https://graph.facebook.com/v2.6/me/subscribed_apps",
	query: {
		access_token: ENV["FB_ACCESS_TKN"]
	},
	header: {
		"X-Hub-Signature": {}
	}
)
puts response.inspect
