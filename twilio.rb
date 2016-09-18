require 'twilio-ruby'
require 'dotenv'
Dotenv.load

STORYTIME_NO  = "+12032023505"

client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']

client.account.messages.create(
  body: "Hi again! To get more stories through Facebook, tap here and enter 'go':\n\njoinstorytime.com/go",
  to: "8603517979",
  from: STORYTIME_NO
)

