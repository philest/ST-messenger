require 'dotenv'
Dotenv.load
require 'httparty'
require 'openssl'

def generate_hmac(content)
  OpenSSL::HMAC.hexdigest('sha1'.freeze, app_secret, content)
end


response = HTTParty.post(
	"https://graph.facebook.com/v2.6/me/subscribed_apps",
	query: {
		access_token: ENV["REMOTE_FB_ACCESS_TKN"]
	}
)
puts response.inspect
