require 'twilio-ruby'
require 'dotenv'
Dotenv.load
from = "+12032023505" # Your Twilio 
to = "+18186897323"
body = "test"


sleep 10

client = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"

	10.times do
		client.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
		sleep 7
	end
sleep 15	

=begin
client2 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"
		client2.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
client3 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"
		client3.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
client4 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"
		client4.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
client5 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"
		client5.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
client6 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"
		client6.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
client7 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"
		client7.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
client8 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"
		client8.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
client9 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
sleep 1
puts "client created"
		client9.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
client10 = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
		client10.account.messages.create(
			:from => from,
			:to => to,
			:body => body
		)
		puts "message sent"
sleep 10
=end
