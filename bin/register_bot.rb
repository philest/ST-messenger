require 'dotenv'
Dotenv.load
# require './ENV_LOCAL'
require 'httparty'


def generate_hmac(content)
  OpenSSL::HMAC.hexdigest('sha1'.freeze, app_secret, content)
end


response = HTTParty.post(
	"https://graph.facebook.com/v2.6/me/subscribed_apps",
	query: {
		access_token: ENV["FB_ACCESS_TKN"]
	}
)
puts response.inspect
