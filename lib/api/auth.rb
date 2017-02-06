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
      notify_admins("The default school or teacher didn't exist for some reason. Failed registration...", e)
      return 404, jsonError(INTERNAL_ERROR, "couldn't create either default school or defualt teacher")
    end

    # TODO: make 'app' something that's passed in from client  :P
    begin
      app_platform = 'app'

      new_user = SIGNUP::create_user(User, phone, first_name, last_name, password, class_code, app_platform, time_zone)
      SIGNUP::register_user(new_user, class_code, password, default_story_number, default_story_number, true)
    rescue Exception => e # TODO, better error handling
      notify_admins("Free-agent creation failed somehow...", e)
      return 404, jsonError(INTERNAL_ERROR, "couldn't create user in a fatal way")
      # TODO: should probably attempt to destroy user
    end
    notify_admins("Free-agent created. #{first_name} #{last_name}, phone: #{phone}, teacher email: #{teacher_email}")

    return CREATE_USER_SUCCESS

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

    default_story_number = 2

    if ([phone, first_name, password, class_code].include? nil) or
       ([phone, first_name, password, class_code].include? '')
       puts "#{phone}#{first_name}#{class_code}"
       return MISSING_CREDENTIALS
    end

    class_code        = class_code.delete(' ').delete('-').downcase

    # maybe have a params[:role], but not yet

    if is_matching_code?(class_code) then
      new_user = SIGNUP::create_user(
        User,
        phone,
        first_name,
        last_name,
        password,
        class_code,
        'app', # TODO: make 'app' something that's passed in from client  :P
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

    else # no matching code, don't sign this user up.
      # basically, this condition is how we differentiate between paying customers and randos
      # no school or teacher found
      return NO_MATCHING_SCHOOL # or something
    end

      CREATE_USER_SUCCESS
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
    refresh_tkn = refresh_token(user.id)
    user.update(refresh_token_digest: Password.create(refresh_tkn))

    return 201, jsonSuccess({ token: refresh_tkn })

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

        return 201, { token: access_token(user.id) }.to_json
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
