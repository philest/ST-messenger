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
require_relative 'helpers/name_codes'
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

# curl -v -H -X POST -d 'phone=8186897323&password=my_pass&first_name=David&last_name=McPeek&code=school' http://localhost:5000/auth/signup

# curl -v -H -X POST -d 'phone=8186897323&password=my_pass' http://localhost:5000/auth/login


# get access token
# refresh_tkn=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0OTgwODYzNzAsImlhdCI6MTQ4MjUzNDM3MCwiaXNzIjoiYmlyZHYuaGVyb2t1YXBwLmNvbSIsInVzZXIiOnsidXNlcl9pZCI6MjMwMH0sInR5cGUiOiJyZWZyZXNoIn0.Y6hNMawxdPC_bYPl0nsEbjfTdL3_BSqPpfPz7Usq1s0
# curl -v -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0OTgwODYzNzAsImlhdCI6MTQ4MjUzNDM3MCwiaXNzIjoiYmlyZHYuaGVyb2t1YXBwLmNvbSIsInVzZXIiOnsidXNlcl9pZCI6MjMwMH0sInR5cGUiOiJyZWZyZXNoIn0.Y6hNMawxdPC_bYPl0nsEbjfTdL3_BSqPpfPz7Usq1s0" -X POST http://localhost:5000/auth/get_access_tkn

# next thing to work on: why is JWT.decode not working?

# login
# curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0OTgwNjQ2NjUsImlhdCI6MTQ4MjUxMjY2NSwiaXNzIjoiYmlyZHYuaGVyb2t1YXBwLmNvbSIsInVzZXIiOnsidXNlcl9pZCI6MTQ2OH19.aD644tTNDlWSuF5jxJpprtqnrjigoWwgGI1J0ltWOOU" http://localhost:5000/api
# 
# test
# access_tkn=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0ODI2MjA3OTYsImlhdCI6MTQ4MjUzNDM5NiwiaXNzIjoiYmlyZHYuaGVyb2t1YXBwLmNvbSIsInVzZXIiOnsidXNlcl9pZCI6MjMwMH0sInR5cGUiOiJhY2Nlc3MifQ.zlXv4MgMM_0HEty1QIAUBs7PYSBMbL7lnBRJ3qFB4qM
# curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0ODI2MjA3OTYsImlhdCI6MTQ4MjUzNDM5NiwiaXNzIjoiYmlyZHYuaGVyb2t1YXBwLmNvbSIsInVzZXIiOnsidXNlcl9pZCI6MjMwMH0sInR5cGUiOiJhY2Nlc3MifQ.zlXv4MgMM_0HEty1QIAUBs7PYSBMbL7lnBRJ3qFB4qM" http://localhost:5000/api/test

class Api < Sinatra::Base
  include ContactHelpers
  include MessageReplyHelpers
  include TwilioTextingHelpers
  include NameCodes
  include BCrypt
  
  use JWTAuth

  helpers Authentication
  helpers SchoolCodeMatcher
  helpers STATUS_CODES
  helpers NameCodes

  use Airbrake::Rack::Middleware

  set :session_secret, ENV['SESSION_SECRET']
  enable :sessions

  # before do
  #   begin
  #     options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
  #     bearer = request.env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
  #     puts "bearer = #{bearer}"
  #     payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options
  #     if payload['type'] != 'access'
  #       halt WRONG_ACCESS_TKN_TYPE, { 'Content-Type' => 'text/plain' }, 'Must be an access token (not refresh).'
  #     end

  #     puts "payload = #{payload.inspect}"

  #     request.env[:user] = payload['user']

  #   rescue JWT::DecodeError => e
  #     p e.inspect
  #     halt NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, 'A token must be passed.'
  #   rescue JWT::ExpiredSignature
  #     halt NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, 'The token has expired.'
  #   rescue JWT::InvalidIssuerError
  #     halt NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, 'The token does not have a valid issuer.'
  #   rescue JWT::InvalidIatError
  #     halt NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, 'The token does not have a valid "issued at" time.'
  #   end

  # end

  get '/test' do
    puts "you are logged in!"
    return SUCCESS
  end

  get '/story_number' do
    user = User.where(id: request.env[:user]['user_id']).first
    if user.nil?
      return NO_EXISTING_USER
    end
    st_no = user.state_table.story_number
    content_type :json
    return {
      story_number: user.state_table.story_number
    }.to_json
  end

  post '/timezone' do

  end

  get '/booklist' do
    file = File.read("#{File.expand_path(File.dirname(__FILE__))}/helpers/fullBookList.json")
    file = JSON.parse(file)
    content_type :json
    return file.to_json
  end

  post '/firebase_id' do
    user = User.where(id: request.env[:user]['user_id']).first
    if user.nil?
      return NO_EXISTING_USER
    end

    user.update(firebase_id: params[:firebase_id])
    return SUCCESS
  end

  post '/story_number' do
    user = User.where(id: request.env[:user]['user_id']).first
    if user.nil?
      return NO_EXISTING_USER
    end
    st_no = user.state_table.story_number
    user.state_table.update(story_number: st_no + 1)

    content_type :json
    return {
      story_number: user.state_table.story_number
    }.to_json
  end

  get '/chat_message' do
    puts "request.env.user = #{request.env[:user]}"
    user = User.where(id: request.env[:user]['user_id']).first
    if user.nil?
      return NO_EXISTING_USER
    end

    st_no = user.state_table.story_number

    # intros
    # english
    I18n.locale = 'en'
    intros_en = I18n.t teacher_school_messaging('scripts.intro.__poc__', user)
    
    # espanish
    I18n.locale = 'es'
    intros_es = I18n.t teacher_school_messaging('scripts.intro.__poc__', user)
    
    # puts intros_en, outros_en
    # puts intros_es, outros_es

    if st_no == 1
      en_intro = intros_en[0]
      es_intro = intros_es[0]
    else
      # indices 1, 2, 3
      index = (st_no % 3)+1
      en_intro = intros_en[index]
      es_intro = intros_es[index]
    end

    # outros
    # get weekday for outros.......
    sw = ScheduleWorker.new
    schedule = sw.get_schedule(st_no)

    current_weekday = sw.get_local_day(Time.now.utc, user)

    next_day = schedule[0] # the first part of the next week by default
    week = '.next_week'
    schedule.each do |day|
      # make me proud
      if day > current_weekday
        next_day = day
        week = '.this_week'
        break
      end
    end

    outro_code = 'scripts.outro.__poc__' + week

    I18n.locale = 'en'
    outros_en = I18n.t teacher_school_messaging(outro_code, user)

    I18n.locale = 'es'
    outros_es = I18n.t teacher_school_messaging(outro_code, user)

    en_outro = outros_en[st_no % 4]
    es_outro = outros_es[st_no % 4]

    en_intro = name_codes(en_intro, user)
    es_intro = name_codes(es_intro, user)

    en_outro = name_codes(en_outro, user, next_day, 'en')
    es_outro = name_codes(es_outro, user, next_day, 'es')

    content_type :json

    return {
      intro: {
        en: en_intro,
        es: es_intro
      },
      outro: {
        en: en_outro,
        es: es_outro
      }
    }.to_json

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

  set :session_secret, ENV['SESSION_SECRET']
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

  get '/check_phone' do
    phone = params[:phone]
    user = User.where(phone: phone).first

    if user.nil?
      return 404
    else
      return 200
    end
  end


  post '/signup' do
    phone       = params[:phone]
    first_name  = params[:first_name]
    last_name   = params[:last_name]
    password    = params[:password]
    code        = params[:code]

    if ([phone, first_name, last_name, password, code].include? nil) or
       ([phone, first_name, last_name, password, code].include? '')
       return MISSING_CREDENTIALS
    end

    code        = code.delete(' ').delete('-').downcase

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

  # post/get with login? 
  # where do we redirect? 

  post '/login' do
    puts "params = #{params}"
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























