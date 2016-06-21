#  app.rb                                     Phil Esterman     
# 
#  The routes controller. Recieves POST from 
#  www.joinstorytime.com/enroll with family phones and names. 
#  --------------------------------------------------------

#sinatra dependencies 
require 'sinatra'
require_relative '../../config/environment.rb'
require_relative 'enroll'

enable :sessions


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
			p e.message
		end
	end

	# setup Twilio
	client = Twilio::REST::Client.new ENV["TW_ACCOUNT_SID"], ENV["TW_AUTH_TOKEN"]
	from = "+12032023505" # Your Twilio number


	# Create the parents
	25.times do |idx|
		if params["phone_#{idx}"] != nil

			begin 
				parent = User.create(:phone =>  params["phone_#{idx}"])
			    parent.update(:name => params["name_#{idx}"]) if params["name_#{idx}"] != nil

				teacher.add_user(parent)

				# ok, as long as the text messaging is done in this block, parents won't be sent duplicate texts
				# because this only happens when they first enter the database table
				body = "Hi, this is #{teacher.signature}. I've signed up our class to get free nightly books on StoryTime. Just click here:\nm.me/490917624435792"

				client.account.messages.create(
					:from => from,
					:to => parent.phone,
					:body => body
				)
				puts "Sent message to #{parent.phone}"

		    rescue Sequel::UniqueConstraintViolation => e
		      	p e.message << " ::> did not insert, already exists in db"
		      	next
		    rescue Sequel::Error => e
		     	p e.message << " ::> failure"
		     	next
			end
		end
	end	
	
	puts User.count






end







