module Authentication

  def authenticate!
    if session[:user]
      return true
    else


    # aubrey's code... including the refresh_token
    unless session[:user] # if there is no session[:user]
      # check the refresh token

      if 



    end

    return 200

  end




#     unless session[:user]
#       # in need of authentication
#       session[:original_request] = request.path_info
#       redirect '/signin'
#     end
#   end
# end