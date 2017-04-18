#  auth.rb                       Aubrey Wahl & David McPeek
#
#
#  The auth controller.
#  "-----""-----""-----""-----""-----""-----""-----""-----""-----""-----""-----"-

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
require_relative 'helpers/signup' # SIGNUP::cool_method
require_relative 'helpers/json_macros'
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

class ResetPassword < Sinatra::Base
  include ContactHelpers
  include MessageReplyHelpers
  include TwilioTextingHelpers
  include NameCodes
  include BCrypt

  require "sinatra/reloader" if development?

  configure :development do
    register Sinatra::Reloader
  end

  use Airbrake::Rack::Middleware

  # use Rack::PostBodyContentTypeParser

  set :session_secret, ENV['SESSION_SECRET']
  enable :sessions

  set :root, File.join(File.dirname(__FILE__), '../')

  helpers JSONMacros
  helpers STATUS_CODES
  helpers AuthenticationHelpers
  helpers SchoolCodeMatcher

  # all of our endpoints return json
  before do
    content_type :json
  end




  # step #1 in phone password reset
  post '/phone/sms' do
    phone = params["phone"]

    # check if user is in DB
    begin
      user = User.where(phone: phone).first
      user_id = user.id.to_s
    rescue Exception => e # TODO, better error handling
      return 404, jsonError(PHONE_NOT_FOUND, 'could not find that phone in db')
    end



    # encode JWTs
    begin

      start_time = Time.now.to_i
      life = 5.minutes
      life_length = life.to_i
      random_code = 4.times.map{rand(10)}.join  # returns int >= argument

      jwt1 = forgot_password_encode(user_id, start_time, life_length, random_code)
      jwt2 = forgot_password_access_token(user_id, start_time, life_length)
      puts jwt1
    rescue Exception => e # TODO, better error handling
      puts e
      return 404, jsonError(INTERNAL_ERROR, 'could not create token')
    end


    puts "CERODA: #{random_code}"
    # update db entry
    begin
      user.set_reset_password_token(random_code)
    rescue Exception => e # TODO, better error handling
      puts e
      return 504, jsonError(INTERNAL_ERROR, 'could not update reset_pswd_digest')
    end

    TextingWorker.perform_async("Your Storytime confirmation code is: #{random_code}", phone)



    # jwt2 is essentially an access token
    return 201, jsonSuccess({
      token: jwt2,
    })

  end






  # step #2 in phone password reset
  post '/phone/code' do
    token = params["token"] # access JWT, given to user in previous step
    random_code  = params["randomCode"].to_s



    # check if minimal credentials sent
    if ([token, random_code].include? nil) or
       ([token, random_code].include? '')
       return 404, jsonError(CREDENTIALS_MISSING, 'missing token or randomCode')
    end



    # decode JWT from user (access token)
    payload = forgot_password_decode(token)
    if decode_error(payload) 
      return 404, jsonError(payload[:code], payload[:title])
    end


    user_id = payload['user']['user_id'].to_s
    start_time = payload['iat'].to_i
    life_length = payload['life_length'].to_i



    # check if user is in db
    begin
      user = User.where(id: user_id).first
      if user.nil?
        return 404, jsonError(USER_NOT_EXIST, 'could not find user')
      end
    rescue Exception => e
      puts e
      return 404, jsonError(INTERNAL_ERROR, 'could not find user')
    end



    jwt1 = forgot_password_encode(user_id, start_time, life_length, random_code)
    puts jwt1
    puts user.authenticate_reset_password_token(random_code)
    if !user.authenticate_reset_password_token(random_code)
      return 404, jsonError(SMS_CODE_WRONG, 'wrong text-in code')
    end

    return 200, jsonSuccess({
      token: jwt1,
    })

  end






  # step #3 in phone password reset
  post '/phone/reset' do
    token = params["token"] # db-stored JWT, given to user in previous step
    password = params["password"]
    puts password



    # check if minimal credentials sent
    if ([token, password].include? nil) or
       ([token, password].include? '')
       return 404, jsonError(CREDENTIALS_MISSING, 'missing token or randomCode')
    end



    # decode JWT from user (access token)
    # this catches if JWT is expired, etc
    payload = forgot_password_decode(token)
    if decode_error(payload)
      return 404, jsonError(payload[:code], payload[:title])
    end

    user_id = payload['user']['user_id']
    random_code = payload['random_code'].to_s
    puts "CODE: #{random_code}"

    # check if user is in db
    begin
      user = User.where(id: user_id).first
      if user.nil?
        return 404, jsonError(USER_NOT_EXIST, 'could not find user')
      end
    rescue Exception => e
      puts e
      return 404, jsonError(INTERNAL_ERROR, 'could not find user')
    end




    # check if passed token matches stored token
    if !user.authenticate_reset_password_token(random_code)
      return 404, jsonError(SMS_CODE_WRONG, 'probably have a bad token somehow')
    end


    # update user's password
    begin
      user.set_password(password)
    rescue Exception => e
      puts e
      return 404, jsonError(PASSWORD_UPDATE_FAIL, 'could not update password, all else was good tho')
    end

    return 201

  end


  post '/email/request' do

    puts "hello darling, you're in /email/request!"

    puts params

    return 201, jsonSuccess({
      msg: "WE ARE IN /EMAIL FOR RESET_EMAIL, AMIGO!!!!!",
    })

  end



  # step #1 in email password reset
  post '/email' do
    phone = params["email"]


    puts "WE ARE IN /EMAIL FOR RESET_EMAIL!!!!! ;)"
    return 201, jsonSuccess({
      msg: "WE ARE IN /EMAIL FOR RESET_EMAIL, AMIGO!!!!!",
    })

    # check if user is in DB
    begin
      user = User.where(email: email).first
      user_id = user.id.to_s
    rescue Exception => e # TODO, better error handling
      return 404, jsonError(PHONE_NOT_FOUND, 'could not find that phone in db')
    end

    # encode JWTs
    begin
      start_time = Time.now.to_i
      life = 5.minutes
      life_length = life.to_i
      random_code = 4.times.map{rand(10)}.join  # returns int >= argument

      jwt1 = forgot_password_encode(user_id, start_time, life_length, random_code)
      jwt2 = forgot_password_access_token(user_id, start_time, life_length)

    rescue Exception => e # TODO, better error handling
      puts e
      return 404, jsonError(INTERNAL_ERROR, 'could not create token')
    end

    # update db entry
    begin
      # puts "digest #{Password.create(jwt1)}"
      user.set_reset_password_token(jwt1)
    rescue Exception => e # TODO, better error handling
      puts e
      return 504, jsonError(INTERNAL_ERROR, 'could not update reset_pswd_digest')
    end

    TextingWorker.perform_async("Your Storytime confirmation code is: #{random_code}", phone)


    # jwt2 is essentially an access token
    return 201, jsonSuccess({
      token: jwt2,
    })

  end


end
