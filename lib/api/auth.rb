#  auth.rb                                     David McPeek
#                (with significant assistance from A. Wahl)
#
#  The auth controller.
#  --------------------------------------------------------

#sinatra dependencies
require 'sinatra/base'
require 'sidekiq'
require 'sidekiq/web'

require 'twilio-ruby'
require 'pony'
require 'dotenv'
require 'httparty'
require 'bcrypt'
require 'rack/contrib'

Dotenv.load if ENV['RACK_ENV'] != 'production'

require_relative '../bot/dsl'
# require_relative '../../config/environment'
require_relative '../../config/pony'
require_relative '../../config/initializers/redis'
require_relative '../../config/initializers/airbrake'
require_relative '../helpers/contact_helpers'
require_relative '../helpers/reply_helpers'
require_relative '../helpers/twilio_helpers'
require_relative '../helpers/name_codes'
require_relative '../helpers/match_school_code'
require_relative '../helpers/name_codes'
require_relative '../workers'

require_relative 'helpers/authentication'
require_relative 'constants/statusCodes'




# CREATE USER: (assumes school with code 'school' already exists)
# curl -v -H -X POST -d 'phone=8186897323&password=my_pass&first_name=David&last_name=McPeek&code=school' http://localhost:5000/auth/signup
#
# curl -v -X POST -H "Content-Type: application/json" -d '{"phone":"8186897323","password":"my_pass","first_name":"David","last_name":"McPeek","code":"school"}' http://localhost:5000/auth/signup
# curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' http://localhost:3000/api/login

# LOGIN, gets refresh token
# curl -v -H -X POST -d 'phone=8186897323&password=my_pass' http://localhost:5000/auth/login

# /get_access_token from refresh token
# curl -v -H "Authorization: Bearer THE_REFRESH_TOKEN" -X POST http://localhost:5000/auth/get_access_tkn

# USING THE API
# curl -H "Authorization: Bearer THE_ACCESS_TOKEN" http://localhost:5000/api/*

class AuthAPI < Sinatra::Base
  include ContactHelpers
  include MessageReplyHelpers
  include TwilioTextingHelpers
  include NameCodes
  include BCrypt

  use Airbrake::Rack::Middleware

  # use Rack::PostBodyContentTypeParser

  set :session_secret, ENV['SESSION_SECRET']
  enable :sessions

  set :root, File.join(File.dirname(__FILE__), '../')

  helpers STATUS_CODES
  helpers AuthenticationHelpers
  helpers SchoolCodeMatcher

  helpers do

  end

  before do
    headers 'Content-Type' => 'text/html; charset=utf-8'
  end

  get '/check_phone' do
    puts 'he'
    phone = params[:phone]
    user = User.where(phone: phone).first

    if user.nil?
      return 420
    else
      return 204
    end
  end


  post '/signup' do
    puts "params = #{params}"
    phone       = params["phone"]
    first_name  = params["first_name"]
    last_name   = params["last_name"]
    password    = params["password"]
    class_code  = params["class_code"]
    time_zone   = params["time_zone"]

    default_story_number = 3

    if ([phone, first_name, password, class_code].include? nil) or
       ([phone, first_name, password, class_code].include? '')
       return MISSING_CREDENTIALS
    end

    class_code        = class_code.delete(' ').delete('-').downcase

    # maybe have a params[:role], but not yet

    if is_matching_code?(class_code) then
      userData = {
        phone: phone,
        first_name: first_name,
        last_name: last_name,
        class_code: class_code,
        platform: 'app'
      }

      if (time_zone) then
        userData['tz_offset'] = time_zone
      end

      new_user = User.create(userData)
      new_user.set_password(password)
      new_user.state_table.update(story_number: default_story_number)
      # associate school/teacher, whichever
      new_user.match_school(class_code)
      new_user.match_teacher(class_code)
      # great! fantastic, resource created
      return CREATE_USER_SUCCESS

    else # no matching code, don't sign this user up.
      # basically, this condition is how we differentiate between paying customers and randos
      # no school or teacher found
      return NO_MATCHING_SCHOOL # or something
    end

  end

  post '/login' do
    phone       = params[:phone]
    password    = params[:password]

    if phone.nil? or password.nil? or phone.empty? or password.empty?
      return MISSING_CREDENTIALS
    end

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
      puts "bearer = #{bearer}"
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      if payload['type'] != 'refresh'
        puts "WRONG TYPE!!!!!!!!!"
        return WRONG_ACCESS_TKN_TYPE
      end

      user_id = payload['user']['user_id']

      # check in db and cross-reference the bearer and the refres_tkn_digest
      user = User.where(id: user_id).first
      if user.nil?
        puts "NO_EXISTING_USER!"
        return NO_EXISTING_USER
      end

      refresh_tkn_hash   = Password.new(user.refresh_token_digest)
      if refresh_tkn_hash == bearer
        # generate a refresh tkn with different stats
        content_type :json
        return { token: access_token(user.id) }.to_json
      end

    rescue JWT::ExpiredSignature
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
    rescue JWT::InvalidIssuerError
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
    rescue JWT::InvalidIatError
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
    rescue JWT::DecodeError
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
    end

  end

  # signout????

end
