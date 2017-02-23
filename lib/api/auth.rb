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

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end
  end


  helpers do

    def check_if_user_exists (username)
      puts 'he'

      if username.nil? || username.empty?
        # 400 error is a vestige
        return 400, jsonError(CREDENTIALS_MISSING, 'missing phone or email!')
      end

      if username.is_email?
        user = User.where(email: username).first
      elsif username.is_phone?
        user = User.where(phone: username).first
      else
        return 404, jsonError(CREDENTIALS_INVALID, 'malformed phone or email')
      end

      if user.nil?
        # user not yet created (this is fine)
        return 420
      else
        # user already exists
        return 204
      end
    end



  end

  # all of our endpoints return json
  before do
    content_type :json
  end



  # this is a vestigial route :(
  # simply forward to /check_username
  get '/check_phone' do
    username = params[:phone]
    return check_if_user_exists(username)
  end




  post '/check_username' do
    username = params[:username] || params[:phone]
    return check_if_user_exists(username)
  end






  post '/signup_free_agent' do
    # required params
    username    = params['username'] || params["phone"]
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

    if ([username, first_name, password].include? nil) || ([username, first_name, password].include? '')
      return 404, jsonError(MISSING_CREDENTIALS, "empty username or password or first_name")
    end

    puts "we have our params!"

    # if default school/teacher doesn't exists, create it
    begin
      # shouldn't these be switched around?
      puts "about to create school/teafcher"
      default_school, default_teacher = SIGNUP::create_free_agent_school(School, Teacher, school_code_expression)
      puts "done with that shit man"
    rescue Exception => e
      puts "["
      puts e
      puts "]"

      puts "A FUCKING EXCEPTION WAS RAISED MAN"
      if (ENV["RACK_ENV"] != "development")
        notify_admins("The default school or teacher didn't exist for some reason. Failed registration...", e)
      end
      return 404, jsonError(INTERNAL_ERROR, "couldn't create either default school or defualt teacher")
    end

    # TODO: make 'app' something that's passed in from client  :P
    begin
      app_platform = 'app'

      new_user = SIGNUP::create_user(User, username, first_name, last_name, password, class_code, app_platform, role, time_zone)
      if new_user.nil?
        return CREDENTIALS_INVALID, jsonError(CREDENTIALS_INVALID, 'user was not created')
      end


      SIGNUP::register_user(new_user, class_code, password, default_story_number, default_story_number, true)
    rescue Exception => e # TODO, better error handling
      puts "FOR SOME REASON THIS SHIT FAILED"
      if (ENV["RACK_ENV"] != "development")
        notify_admins("Free-agent creation failed somehow...", e)
      end
      return 404, jsonError(INTERNAL_ERROR, "couldn't create user in a fatal way")
      # TODO: should probably attempt to destroy user
    end


    if ENV['RACK_ENV'] != 'development'
      notify_admins("Free-agent (#{role}) created. #{first_name} #{last_name}, username: #{username}, teacher email: #{teacher_email}")
    end


    return CREATE_USER_SUCCESS, jsonSuccess({dbuuid: new_user.id})

  end



  post '/signup' do
    puts "params = #{params}"
    username    = params["username"] || params["phone"]
    first_name  = params["first_name"]
    last_name   = params["last_name"]
    password    = params["password"]
    class_code  = params["class_code"]
    time_zone   = params["time_zone"]
    role        = params["role"] || "parent"

    default_story_number = 2


    # check if minimal credentials sent
    if ([username, first_name, password, class_code].include? nil) or
       ([username, first_name, password, class_code].include? '')
       puts "#{username}#{first_name}#{class_code}"
       return MISSING_CREDENTIALS, jsonError(MISSING_CREDENTIALS, 'missing username/first_name/class_code')
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
      username,
      first_name,
      last_name,
      password,
      class_code,
      'app', # TODO: make 'app' something that's passed in from client  :P
      role,
      time_zone,
    )

    if new_user.nil?
      return CREDENTIALS_INVALID, jsonError(CREDENTIALS_INVALID, 'user was not created')
    end


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












  post '/login' do
    username    = params[:username] || params[:phone]
    password    = params[:password]

    if username.nil? or password.nil? or username.empty? or password.empty?
      return MISSING_CREDENTIALS, jsonError(MISSING_CREDENTIALS, 'empty username or password')
    end

    puts "username = #{username}"

    # check out /models/helpers/phone-email.rb for the class method #where_username_is
    user = User.where_username_is(username)


    if user.nil?
      return NO_EXISTING_USER, jsonError(NO_EXISTING_USER, "couldn't find user in db")
    end

    if !user.authenticate(password)
      return 404, jsonError(WRONG_PASSWORD, 'wrong password')
    end

    # create refresh_tkn and send to user
    refresh_token = create_refresh_token(user.id)
    user.update(refresh_token_digest: Password.create(refresh_token))

    return 201, jsonSuccess({ token: refresh_token, dbuuid: user.id, role: user.role })

  end

  # TODO: clean up token errors
  post '/get_access_tkn' do
    begin

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      if payload['type'] != 'refresh'
        return WRONG_ACCESS_TKN_TYPE, jsonError(WRONG_ACCESS_TKN_TYPE, 'wrong token type, expected refresh')
      end

      user_id = payload['user']['user_id']

      # check in db and cross-reference the bearer and the refres_tkn_digest
      user = User.where(id: user_id).first
      if user.nil?
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
