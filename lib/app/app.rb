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



post '/enroll' do
	

	# Create the parents
	25.times do |idx|
		if params["phone_#{idx}"]

			user = User.create(phone: params["phone_#{idx}"])
			if params["name_#{idx}"]
				user.update(name: params["name_#{idx}"])
			end
		end
	end	

	puts User.count



end
