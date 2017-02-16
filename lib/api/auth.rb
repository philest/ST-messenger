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

class AuthAPI < Sinatra::Base
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

  post '/reset_password' do
    # not sure if it'll be in JSON?
    # get phone
    phone = params['phone']
    if phone.nil? or phone.empty?
      return [MISSING_CREDENTIALS, { 'Content-Type' => 'text/plain' }, ['Missing phone param!']]
    end
    user = User.where(phone: phone).first
    if user.nil?
      return [NO_EXISTING_USER, { 'Content-Type' => 'text/plain' }, ["User with phone #{phone} doesn't exist"]]
    end

    # get a random string of integers...
    generate_code = proc do
      Array.new(4){[*'0'..'9'].sample}.join
    end

    new_password = generate_code.call()
    user.set_password(new_password)

    # now text them.....
    case user.locale
    when 'es'
      msg = "Aquí está tu nueva contraseña:\n#{new_password}"
    else
      msg = "Here's your new StoryTime password:\n#{new_password}"
    end
    puts "I mean, maybe"

    TextingWorker.perform_async(msg, phone)

    return [SUCCESS, { 'Content-Type' => 'text/plain' }, ["Password updated for user with phone #{phone}."]]
  end


  post '/signup_free_agent' do
    # required params
    phone       = params["phone"]
    first_name  = params["first_name"]
    password    = params["password"]
    role        = params["role"] || "parent"

    # mostly optional params
    last_name   = params["last_name"]
    time_zone   = params["time_zone"]
    teacher_email = params["teacher_email"]

    locale      = params["locale"] || 'en'

    school_code_base = 'freeagent'
    school_code_expression = "#{school_code_base}|#{school_code_base}-es"

    class_code = "#{school_code_base}#{(locale === 'es' ? '-es' : '')}1"

    puts class_code

    default_story_number = 2

    if ([phone, first_name, password].include? nil) || ([phone, first_name, password].include? '')
      return 404, jsonError(MISSING_CREDENTIALS, "empty username or password or first_name")
    end

    # if default school/teacher doesn't exists, create it
    begin
      default_school, default_teacher = SIGNUP::create_free_agent_school(School, Teacher, school_code_expression)
    rescue Exception => e
      puts "["
      puts e
      puts "]"
      if (ENV["RACK_ENV"] != "development")
        notify_admins("The default school or teacher didn't exist for some reason. Failed registration...", e)
      end
      return 404, jsonError(INTERNAL_ERROR, "couldn't create either default school or defualt teacher")
    end

    # TODO: make 'app' something that's passed in from client  :P
    begin
      app_platform = 'app'

      new_user = SIGNUP::create_user(User, phone, first_name, last_name, password, class_code, app_platform, role, time_zone)
      SIGNUP::register_user(new_user, class_code, password, default_story_number, default_story_number, true)
    rescue Exception => e # TODO, better error handling
      notify_admins("Free-agent creation failed somehow...", e)
      return 404, jsonError(INTERNAL_ERROR, "couldn't create user in a fatal way")
      # TODO: should probably attempt to destroy user
    end
    notify_admins("Free-agent created. #{first_name} #{last_name}, phone: #{phone}, teacher email: #{teacher_email}")

    return CREATE_USER_SUCCESS, jsonSuccess({dbuuid: new_user.id})

  end

  # this is how to call another route, but not treat it as a redirect
  # post '/merge_test' do
  #   status, headers, body = call env.merge("PATH_INFO" => '/merge_redirect')
  #   [status, headers, body.map(&:upcase)]
  # end

  # post '/merge_redirect' do
  #   puts params # the params are passed :)
  #   puts "REDIRECTED"
  #   200
  # end











  post '/signup' do
    puts "params = #{params}"
    phone       = params["phone"]
    first_name  = params["first_name"]
    last_name   = params["last_name"]
    password    = params["password"]
    class_code  = params["class_code"]
    time_zone   = params["time_zone"]
    role        = params["role"] || "parent"

    default_story_number = 2


    # check if minimal credentials sent
    if ([phone, first_name, password, class_code].include? nil) or
       ([phone, first_name, password, class_code].include? '')
       puts "#{phone}#{first_name}#{class_code}"
       return MISSING_CREDENTIALS, jsonError(MISSING_CREDENTIALS, 'missing phone/first_name/class_code')
    end

    # parse class code
    class_code        = class_code.delete(' ').delete('-').downcase



    # check if class code exists
    if !is_matching_code?(class_code)
      return NO_MATCHING_SCHOOL, jsonError(NO_MATCHING_SCHOOL, 'no matching school found') # or something
    end


    # TODO: being...rescue this
    new_user = SIGNUP::create_user(
      User,
      phone,
      first_name,
      last_name,
      password,
      class_code,
      'app', # TODO: make 'app' something that's passed in from client  :P
      role,
      time_zone,
    )

    SIGNUP::register_user(
      new_user,
      class_code,
      password,
      default_story_number,
      default_story_number,
      true,
    )


    return CREATE_USER_SUCCESS, jsonSuccess({dbuuid: new_user.id})

  end












  # step #1 in phone password reset
  post '/forgot_password_phone' do
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

    rescue Exception => e # TODO, better error handling
      puts e
      return 404, jsonError(INTERNAL_ERROR, 'could not create token')
    end



    # update db entry
    begin
      # puts "digest #{Password.create(jwt1)}"
      user.update(reset_password_token: jwt1)
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
  post '/forgot_password_phone_code' do
    token = params["token"] # access JWT, given to user in previous step
    random_code  = params["randomCode"].to_s



    # check if minimal credentials sent
    if ([token, random_code].include? nil) or
       ([token, random_code].include? '')
       return 404, jsonError(CREDENTIALS_MISSING, 'missing token or randomCode')
    end



    # decode JWT from user (access token)
    payload = forgot_password_decode(token)
    if (payload['user'].nil?)
      return 404, jsonError(payload[:code], payload[:msg])
    end


    user_id = payload['user']['user_id'].to_s



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



    # check if text-in code was correct
    refresh = user.reset_password_token
    stored_random_code = forgot_password_decode(refresh)["random_code"]

    if !(random_code == stored_random_code)
      return 404, jsonError(SMS_CODE_WRONG, 'wrong text-in code')
    end

    return 200, jsonSuccess({
      token: refresh,
    })

  end






  # step #3 in phone password reset
  post '/reset_password_phone' do
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
    if (payload['user'].nil?)
      return 404, jsonError(payload[:code], payload[:msg])
    end

    user_id = payload['user']['user_id']



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

    refresh = user.reset_password_token

    # check if passed token matches stored token
    if token != refresh
      return 404, jsonError(payload.code, payload.msg)
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










  post '/login' do
    phone       = params[:phone]
    password    = params[:password]

    if phone.nil? or password.nil? or phone.empty? or password.empty?
      return MISSING_CREDENTIALS, jsonError(MISSING_CREDENTIALS, 'empty username or password')
    end

    puts "phone = #{phone}"
    user = User.where(phone: phone).first

    if user.nil?
      return NO_EXISTING_USER, jsonError(NO_EXISTING_USER, "couldn't find user in db")
    end

    if !user.authenticate(password)
      return 404, jsonError(WRONG_PASSWORD, 'wrong password')
    end

    # create refresh_tkn and send to user
    tkn = create_refresh_token(user.id)
    user.update(refresh_token_digest: Password.create(tkn))

    return 201, jsonSuccess({ token: tkn, dbuuid: user.id })

  end










  post '/get_access_tkn' do
    begin
      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      if payload['type'] != 'refresh'
        puts "WRONG TYPE!!!!!!!!!"
        return WRONG_ACCESS_TKN_TYPE, jsonError(WRONG_ACCESS_TKN_TYPE, 'wrong token type, expected refresh')
      end

      user_id = payload['user']['user_id']

      # check in db and cross-reference the bearer and the refres_tkn_digest
      user = User.where(id: user_id).first
      if user.nil?
        puts "NO_EXISTING_USER!"
        return NO_EXISTING_USER, jsonError(NO_EXISTING_USER, 'no such user with that refresh tkn')
      end

      refresh_tkn_hash   = Password.new(user.refresh_token_digest)

    rescue JWT::ExpiredSignature
      return NO_VALID_ACCESS_TKN, jsonError(NO_VALID_ACCESS_TKN, 'The token has expired')

    rescue JWT::InvalidIssuerError
      return NO_VALID_ACCESS_TKN, jsonError(NO_VALID_ACCESS_TKN, 'The token does not have a valid issuer')

    rescue JWT::InvalidIatError
      return NO_VALID_ACCESS_TKN, jsonError(NO_VALID_ACCESS_TKN, 'The token does not have a valid "issued at" time.')

    rescue JWT::DecodeError
      return NO_VALID_ACCESS_TKN, jsonError(NO_VALID_ACCESS_TKN, 'A token must be passed in')

    end

    if refresh_tkn_hash == bearer
      return 201, jsonSuccess({ token: access_token(user.id) })
    end
  end

end
