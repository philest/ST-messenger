require 'twilio-ruby'
require 'dotenv'
Dotenv.load

STORYTIME_NO  = "+12032023505"

client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']

client.account.messages.create(
  body: "Hi, this is StoryTime. We'll be texting you free books! Like this:",
  to: "8186897323",
  from: STORYTIME_NO
)

