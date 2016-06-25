require 'twilio-ruby'
class TwilioWorker
 	include Sidekiq::Worker
 	# include Twilio


	def perform(name, number, teacher)
		client = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
		from = "+12032023505" # Your Twilio number
		body = "Hi, this is #{teacher}. I've signed up our class to get free nightly books on StoryTime. Just click here:\njoinstorytime.com/books"
		client.account.messages.create(
			:from => from,
			:to => number,
			:body => body
		)
		puts "Sent message to parent of #{name}"

		# update the user day! TODO: make this a seperate job!
	end
	# TODO, add completed to a DONE pile. some day
end