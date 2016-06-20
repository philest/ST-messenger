#  app.rb                                     Phil Esterman     
# 
#  The routes controller. Recieves POST from 
#  www.joinstorytime.com/enroll with family phones and names. 
#  --------------------------------------------------------

#sinatra dependencies 
require 'sinatra'
require_relative '../../config/environment.rb'

enable :sessions


get '/' do
 'hello world'
end


post '/enroll' do
	puts "enrolling parents..."
	# DO WE WANT to have a secret key or some other validation so that someone can't overload the system with CURL requests to phone numbers?
	# that's a later challenge.

	# TODO : what teacher info will we have?
	if defined? params["teacher_signature"]
				# create a new teacher with a phone number
				signature =  params["teacher_prefix"] + params["teacher_signature"]
				puts "creating new teacher: #{signature}"
				teacher = Teacher.create(:signature => signature)
	end

	# Create the parents
	25.times do |idx|
		if params["phone_#{idx}"] != ''

			begin 
			parent = User.create(:phone =>  params["phone_#{idx}"])
	    parent.update(:name => params["name_#{idx}"]) if params["name_#{idx}"] != ''
	    rescue Sequel::UniqueConstraintViolation => e
	      p e.message << " ::> did not insert, already exists in db"
	    rescue Sequel::Error => e
	      p e.message << " ::> failure"
			end

			if defined? teacher
				teacher.add_user(parent)
			end
		end
	end	
	
	puts User.count


end
