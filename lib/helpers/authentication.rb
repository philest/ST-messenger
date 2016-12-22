require 'jwt' 

# note: traffic to AuthApi only comes from client to server.
# we don't redirect from Api to AuthApi because we'll just send a 
# status of 301 or whatever to client, which will handle redirection from
# there. 

module STATUS_CODES
  CREATE_USER_SUCCESS   = 201
  NO_MATCHING_SCHOOL    = 401
  NO_EXISTING_USER      = 402
  NO_VALID_ACCESS_TKN   = 403
  WRONG_PASSWORD        = 404
end

class JWTAuth

  def initialize app
    @app = app
  end

  def call(env)
    begin
      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      # payload['user']['user_id']
      env[:user] = payload['user']

      # what should I return here? the full env object, or just the user?
      # dependers on what we'll need.....
      @app.call(env)

    rescue JWT::DecodeError
      [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
    rescue JWT::ExpiredSignature
      [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
    rescue JWT::InvalidIssuerError
      [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
    rescue JWT::InvalidIatError
      [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
    end
  end
end

  # store short-term jwt in session[:user]
  # store long-term jwt in db


  # 1. check out how to redirect from middleware on failure to authenticate
  #   (pass in reference to redirect function)
  #   (middleware calls that reference)
  # 2. check out sessions
  #   backup: we just use jwt

  # before do
  #   authenticate!
  # end
  # 
  # check out ruby oauth2 gem implementation

#   def call(env)

#     if session[:user].nil?


#       # check for valid refresh token in db
#       # if none, 
#       #   redirect to login
#       # redirect to '../auth'
#       # 

#     else
#       # get the current jwt session id and shit....
#        begin
#         options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
#         bearer = session[:user]  # the jwt token
#         payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

#         env[:user] = payload['user_id']

#         # what should I return here? the full env object, or just the user?
#         # dependers on what we'll need.....
#         @app.call(env)

#       rescue JWT::DecodeError
#         [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
#       rescue JWT::ExpiredSignature
#         [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
#       rescue JWT::InvalidIssuerError
#         [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
#       rescue JWT::InvalidIatError
#         [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
#       end

#     end

#     # how does the app handle sessions
#     # how does that differ from browsers
#     # 
#     # using jwt:
#     #   requires db + secure hash

#     begin
#       options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
#       bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
#       payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

#       env[:user] = payload['user_id']

#       # what should I return here? the full env object, or just the user?
#       # dependers on what we'll need.....
#       @app.call(env)

#     rescue JWT::DecodeError
#       [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
#     rescue JWT::ExpiredSignature
#       [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
#     rescue JWT::InvalidIssuerError
#       [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
#     rescue JWT::InvalidIatError
#       [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
#     end
#   end

# end

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