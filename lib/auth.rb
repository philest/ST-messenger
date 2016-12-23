#  auth.rb                                     David McPeek      
# 
#  The auth controller. 
#  --------------------------------------------------------

#sinatra dependencies 
require 'sinatra/base'
require 'sidekiq'
require 'sidekiq/web'
require 'twilio-ruby'
# require_relative '../config/environment'
require 'pony'
require 'dotenv'
Dotenv.load if ENV['RACK_ENV'] != 'production'
require_relative '../config/pony'
require_relative 'workers'
require 'httparty'
require_relative 'helpers/contact_helpers' 
require_relative 'helpers/reply_helpers'
require_relative 'helpers/twilio_helpers'
require_relative 'helpers/name_codes'
require_relative 'helpers/authentication'
require_relative 'helpers/match_school_code'
# require_relative 'helpers/generate_phone_image'
require_relative 'bot/dsl'
# may want to have an app_dsl
require_relative '../config/initializers/airbrake'
require_relative '../config/initializers/redis'
require 'bcrypt'


# 2 parts:
# 1. login module.
#   if user does not have a session or refresh_token, they are taken through the login/signup process
#   success with this redirects them to the api endpoing that they requested
# 2. api module
#   for this we'll have a jwt middleware which validates the user's jwt. 
#   if there is no valid jwt, the user is redirected to login. 
#   
#   
# questions:
# 1. two different modules for login?
# 2. use middleware?
# 3. what again are the responses?
# 
# 

# curl -v -H -X POST -d 'phone_no=8186897323&password=my_pass' http://localhost:5000/auth/signin

# curl -v -X POST http://localhost:5000/auth/signin -d '{"phone_no": "8186897323", "password": "my_pass"}'


# curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOiIxNTU1MjAwMCIsImlhdCI6MTQ4MjQ2NzAxNywiaXNzIjoiYmlyZHYuaGVyb2t1YXBwLmNvbSIsInVzZXIiOnsidXNlcl9pZCI6MTQ2OH19.dXZVtBlpj8ETA4dRnyqP-BOuvbZXwSsKMVneYVwI0XA" http://localhost:5000/api

class Api < Sinatra::Base
  use JWTAuth

  get '/' do
    puts "you are logged in!"
    return "you are logged in!"
  end

  # endpoints

  # at each endpoing
  # if fails auth jwt
  #   redirect to AuthApi

end

class AuthApi < Sinatra::Base
  include ContactHelpers
  include MessageReplyHelpers
  include TwilioTextingHelpers
  include NameCodes
  include BCrypt

  use Airbrake::Rack::Middleware

  set :session_secret, "328479283uf923fu8932fu923uf9832f23f232"
  enable :sessions

  set :root, File.join(File.dirname(__FILE__), '../')

  helpers Authentication
  helpers SchoolCodeMatcher
  helpers STATUS_CODES

  helpers do

  end

  before do
    headers 'Content-Type' => 'text/html; charset=utf-8'
  end

  post '/signup' do
    phone       = params[:phone_no]
    first_name  = params[:first_name]
    last_name   = params[:last_name]
    password    = params[:password]
    code        = params[:code].delete(' ').delete('-').downcase
    # maybe have a params[:role], but not yet

    if is_matching_code?(code) then
      new_user = User.create(phone: phone, first_name: first_name, last_name: last_name, platform: 'app')
      new_user.set_password(password)
      # associate school/teacher, whichever
      new_user.match_school(code)
      new_user.match_teacher(code)

      # great! fantastic, resource created
      return CREATE_USER_SUCCESS

    else # no matching code, don't sign this user up.
      # basically, this condition is how we differentiate between paying customers and randos
      # no school or teacher found
      return NO_MATCHING_SCHOOL # or something
    end

  end

  # post/get with signin? 
  # where do we redirect? 

  post '/signin' do
    puts "params = #{params}"
    phone       = params[:phone_no]
    password    = params[:password]

    puts "phone = #{phone}"
    puts "password = #{password}"
    user = User.where(phone: phone).first
    puts "user = #{user.inspect}"

    if user.nil?
      return NO_EXISTING_USER
    end

    if user.authenticate(password) == true
      # create refresh_tkn and send to user
      content_type :json
      refresh_tkn = refresh_token(user.id)
      user.update(refresh_token_digest: Password.create(refresh_tkn))
      return { token: refresh_tkn }.to_json
    else
      return WRONG_PASSWORD
    end
  end

  post '/get_access_tkn' do
    begin
      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      # the bearer is the refresh_token
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      user_id = payload['user']['user_id']

      # check in db and cross-reference the bearer and the refres_tkn_digest
      user = User.where(id: user_id).first
      if user.nil?
        return NO_EXISTING_USER
      end

      refresh_tkn_hash   = Password.new(user.refresh_token_digest)
      if refresh_tkn_hash == bearer
        # generate a refresh tkn with different stats
        content_type :json
        return { token: access_token(user.id) }.to_json
      end

    rescue JWT::DecodeError
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
    rescue JWT::ExpiredSignature
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
    rescue JWT::InvalidIssuerError
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
    rescue JWT::InvalidIatError
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
    end
    
  end

  # signout????

end























