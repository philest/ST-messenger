#  app.rb                                     Phil Esterman     
# 
#  The routes controller. Recieves POST from 
#  www.joinstorytime.com/enroll with family phones and names. 
#  --------------------------------------------------------

#sinatra dependencies 
require 'sinatra'
require_relative '../../config/environment.rb'
require 'sidekiq'
require 'twilio-ruby'
require_relative "../worker"

enable :sessions

# aubrey 3013328953
# phil 5612125831
# david 8186897323


get '/' do
 'hello world'
end

get '/sms' do 
	# begin
	phone = params[:From][2..-1]
	user = User.where(:phone => phone).first
	# rescue	
	# end
	twiml = Twilio::TwiML::Response.new do |r|
		r.Message "StoryTime: Hi, we'll send your text to #{user.teacher.signature}. They'll see it next time they are on their computer."
	end
	twiml.text
end



post '/enroll' do
	puts "enrolling parents..."
	# DO WE WANT to have a secret key or some other validation so that someone can't overload the system with CURL requests to phone numbers?
	# that's a later challenge.

	# TODO : what teacher info will we have?
	if params["teacher_signature"] != nil
		# create a new teacher with a phone number
		if params["teacher_prefix"] == ''
			signature = params["teacher_signature"]
		else
			signature =  params["teacher_prefix"] + " " + params["teacher_signature"]
		end
		begin
			teacher = Teacher.create(:signature => signature)
			puts "created new teacher: #{signature}"
		rescue Sequel::Error => e
			p e.message + " didn't insert teacher, her number already exists in db"
		end
	end

	# setup Twilio
	client = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
	from = "+12032023505" # Your Twilio number


	# Create the parents
	25.times do |idx|
		if params["phone_#{idx}"] != nil
			begin
				parent = User.create(:phone => params["phone_#{idx}"])
				parent.update(:name => params["name_#{idx}"]) if params["name_#{idx}"] != nil
				teacher.add_user(parent)
				puts "added #{parent.name if params["name_#{idx}"] != nil}, phone => #{parent.phone}"
				TwilioWorker.perform_async(params["name_#{idx}"], parent.phone, teacher.signature)
				# body = "Hi, this is #{teacher.signature}. I've signed up our class to get free nightly books on StoryTime. Just click here:\nm.me/490917624435792"
				# client.account.messages.create(
				# 	:from => from,
				# 	:to => parent.phone,
				# 	:body => body
				# )
				# puts "Sent message to #{parent.phone}"
			rescue Sequel::Error => e
				puts e.message + " - didn't insert user" 
			end
		end
	end	
	status 201
end



