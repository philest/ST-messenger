require 'twilio-ruby'
require 'dotenv'
Dotenv.load

STORYTIME_NO  = "+12032023505"

client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']

client.account.messages.create(
  body: "¡Perdón! Aquí está en español. :)",
  to: "2035354292",
  from: STORYTIME_NO
)

