require 'dotenv'
Dotenv.load
require 'httparty'
require 'openssl'

def generate_hmac(content)
  OpenSSL::HMAC.hexdigest('sha1'.freeze, app_secret, content)
end

response = HTTParty.post(
	"https://graph.facebook.com/me/messages",
	query: {
		access_token: ENV['RACK_ENV'] == 'production' ? ENV['PRODUCTION_FB_ACCESS_TKN'] : ENV['FB_ACCESS_TKN']
	},
	body: {
		recipient: { 
			id: ENV["DAVID"] 
		},
		message: {
			text: "Hello there, you rascal! Call me ;)"
		}
	}
)
puts response.inspect
