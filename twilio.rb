require 'twilio-ruby'
require 'dotenv'
Dotenv.load

STORYTIME_NO  = "+12032023505"

STORYTIME_TEST_NO = "+12033496257"

client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']

line1 = "Baby Bird\n\nThe smallest of the baby birds\nWas too afraid to fly.\nHis sisters flew, his brothers too,\nBut baby bird just cried. 1"
line2 = "His mother said, \"Oh baby bird!\"\n\"You'll do it if you try!\"\n\"I promise you can do it son,\"\n\"A mother never lies!\" 2"
line3 = "And baby bird trusted his mom,\nSo once he dried his eyes,\nHe bravely leapt out from the nest\nAnd flew into the sky. 3\n\nThe End"

# @message = client.account.messages.get("M1ea228a51d444121b0f5f94a63daee0a")
# puts @message.body

client.account.messages.create(
  body: "Would you like us to send the rest of the stories?",
  # to: "7203388240",
  from: STORYTIME_NO
)

