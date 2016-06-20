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
	if defined? params["teacher_name"]
		if defined? params["teacher_phone"]
			if not Teacher.where(:phone => ?, params["teacher_phone"]).empty?
				# this teacher already exists, use their profile
				puts "this teacher is already enrolled, using their profile"
				teacher = Teacher.where(:phone => ?, params["teacher_phone"]).first
			else # this is a new teacher in the system
				# create a new teacher with a phone number
				puts "creating new teacher: #{params['teacher_name']}"
				teacher = Teacher.create(:name => ?, :phone => ?, params["teacher_name"], params["teacher_phone"])
			end
		else # teacher didn't input a phone number
			puts "creating new teacher: #{params['teacher_name']}"
			teacher = Teacher.create(:name => ?, params["teacher_name"]) if params["teacher_name"]
			classroom = Classroom.create
			teacher.add_classroom(classroom)
		end
	end

	25.times do |idx|
		if defined? params["phone_#{idx}"]
			parent = User.create(:phone => ?, params["phone_#{idx}"])
			parent.update(:name => ?, params["name_#{idx}"]) if params["name_#{idx}"]
			if defined? teacher
				teacher.add_user(parent)
				classroom.add_user(parent)
			end
		end
	end	
	puts User.count
end
