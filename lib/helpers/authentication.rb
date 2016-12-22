require 'jwt' 

# need to add ENV['JWT_SECRET'] and ENV['JWT_ISSUER']

module Authentication
  
  def token(user_id)
    JWT.encode payload(user_id), ENV['JWT_SECRET'], 'HS256'
  end

  def payload(user_id)
    {
      exp: 6.months,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      user: {
        user_id: user_id
      }
    }
  end

  def authenticate!
    unless session[:user]
      session[:original_request] = request.path_info

      return login_helper()

      # redirect to '/signin'
    end
  end
end

#     unless session[:user]
#       # in need of authentication
#       session[:original_request] = request.path_info
#       redirect '/signin'
#     end
#   end
# end