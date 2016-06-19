#  app.rb                                     Phil Esterman     
# 
#  The routes controller. Recieves POST from 
#  www.joinstorytime.com/enroll with family phones and names. 
#  --------------------------------------------------------

#siantra dependencies 
require 'sinatra'
require_relative '../../config/environment.rb'

enable :sessions


get '/' do
 'hello world'
end

get '/enroll' do 
	
	# register the users, with names if possible
	25.times do |idx|
		if params["\"phone_#{idx}\""]
			user = User.create(phone: params["phone_#{idx}"])
			if params["name_#{idx}"]
				user.update(name: params["name_#{idx}"])
			end
		end
	end	

	#TODO hook the users to their teacher

end


post '/enroll' do
	
	'hello world'

	puts params

	require 'pry'
	binding.pry

	25.times do |idx|
		if params["phone_#{idx}"]
			user = User.create(phone: params["phone_#{idx}"])
			if params["name_#{idx}"]
				user.update(name: params["name_#{idx}"])
			end
		end
	end	

	puts User.count

	# user = User.create(:name => param, :phone => param1)
	# teacher = Teacher.create(:name => name, :email => email, :school => school)
	# user.teacher = teacher



end
