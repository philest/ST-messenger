#  auth.rb                                     David McPeek
#                (with significant assistance from A. Wahl)
#
#  The user api controller.
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
require_relative 'middleware/authorizeEndpoint'
require_relative 'constants/statusCodes'
require_relative 'constants/userID'


# CREATE USER: (assumes school with code 'school' already exists)
# curl -v -H -X POST -d 'phone=8186897323&password=my_pass&first_name=David&last_name=McPeek&code=school' http://localhost:5000/auth/signup
#
# curl -v -X POST -H "Content-Type: application/json" -d '{"phone":"8186897323f","password":"my_pass","first_name":"David","last_name":"McPeek","code":"school"}' http://localhost:5000/auth/signup
# curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' http://localhost:3000/api/login

# LOGIN, gets refresh token
# curl -v -H -X POST -d 'phone=8186897323&password=my_pass' http://localhost:5000/auth/login
# curl -H "Content-Type: application/json" -X POST -d '{"phone":"8186897323","password":"my_pass"}' http://localhost:5000/auth/login

# /get_access_token from refresh token
# curl -v -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0OTgxODg2MjEsImlhdCI6MTQ4MjYzNjYyMSwiaXNzIjoiYmlyZHYuaGVyb2t1YXBwLmNvbSIsInVzZXIiOnsidXNlcl9pZCI6Mjc0M30sInR5cGUiOiJyZWZyZXNoIn0.yp2ETJaszFZfXuaxdSMH7kLuaxZEAQQ59HaEhnNjM1w" -X POST http://localhost:5000/auth/get_access_tkn

# USING THE API
# curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0ODI3MjMwMzksImlhdCI6MTQ4MjYzNjYzOSwiaXNzIjoiYmlyZHYuaGVyb2t1YXBwLmNvbSIsInVzZXIiOnsidXNlcl9pZCI6Mjc0M30sInR5cGUiOiJhY2Nlc3MifQ.-9q-Ag8m9APZYO8AUfP_kenfSFaemqvw0zXJXsOdOkc" http://localhost:5000/api/*

class UserAPI < Sinatra::Base
  include ContactHelpers
  include MessageReplyHelpers
  include TwilioTextingHelpers
  include NameCodes
  include BCrypt


  helpers STATUS_CODES
  helpers AuthenticationHelpers
  helpers SchoolCodeMatcher
  helpers NameCodes

  use AuthorizeEndpoint
  use Airbrake::Rack::Middleware

  configure do
    puts USER_IDS::TEACHER
    spex =  JSON.parse(File.read("#{File.expand_path(File.dirname(__FILE__))}/data/bookSpecs.json"))
    set bookSpecs: {
      time_last_updated: spex['timeLastUpdated'].to_i,
      json: spex['specs'],
    }
    set curriculum: JSON.parse(File.read("#{File.expand_path(File.dirname(__FILE__))}/data/curriculum.json"))
    set schedule: [
      {
        "storyNumber": 5,
        schedule: [0,0,0,1,0,0,0] # starts on monday
      },
      {
        "storyNumber": 10000,
        schedule: [0,1,0,1,0,0,0]
      },
    ]
  end

  # use Rack::PostBodyContentTypeParser

  set :session_secret, ENV['SESSION_SECRET']
  enable :sessions

  get '/test' do
    puts "you are logged in!"
    return SUCCESS
  end

  get '/story_number' do
    st_no = params['story_number']
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
    user = User.where(id: request.env[:user]['user_id']).first
    if user.nil?
      return NO_EXISTING_USER
    end

    user.update(timezone: params[:timezone])
    return SUCCESS
  end

  get '/book_list' do
    theTime = params["timeLastUpdated"].to_i
    if( settings.bookSpecs[:time_last_updated] <= theTime)
      return 200
    end

    content_type :json
    return {
      specs: settings.bookSpecs[:json],
      curriculum: settings.curriculum,
      schedule: settings.schedule
    }.to_json
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




  get '/user_data' do
    user = User.where(id: request.env[:user]['user_id']).first
    if user.nil?
      return NO_EXISTING_USER
    end

    user_data = {
      story_number: user.state_table.story_number,
      teacher_signature: user.teacher.signature,
      school_signature: user.school.signature,
      first_name: user.first_name,
    }

    content_type :json
    return user_data.to_json
  end



  post '/user_data' do
    puts 'peepee'
    user = User.where(id: request.env[:user]['user_id']).first
    if user.nil?
      return NO_EXISTING_USER
    end

    fcm_token = params['fcm_token']
    platform  = params['platform']

    user_data = {
      platform: platform,
      fcm_token: fcm_token,
    }

    puts user_data

    begin
      puts 'hey'
      user.update(platform: platform, fcm_token: fcm_token)
      puts 'ho'
    rescue Exception => e
      puts e
      return INTERNAL_ERROR
    end


  end

  post '/chat_message' do
    puts "request.env.user = #{request.env[:user]}"
    user = User.where(id: request.env[:user]['user_id']).first
    if user.nil?
      return NO_EXISTING_USER
    end

    st_no = params['story_number']


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

    # return {
    #   intro: {
    #     en: en_intro,
    #     es: es_intro
    #   },
    #   outro: {
    #     en: en_outro,
    #     es: es_outro
    #   }
    # }.to_json


    genMessage = proc { |m, user_id, user_code| { "text" => m,
        "_id" => rand(1000000),
        "createdAt" => Time.now.utc.to_i()*1000,
        "user" => {
          "_id" => user_id,
          "name" => user_code,
        }
      }
    }

    genStory = proc { |n| { "text" => '',
        "_id" => rand(1000000),
        "newStory": n,
        "createdAt" => Time.now.utc.to_i()*1000,
        "user" => {
          "_id" => USER_IDS::APP,
          "name" => "__APP__",
        }
      }
    }

    msgs = { messages: {
        en: [
          genStory.call(st_no),
          genMessage.call(en_intro, USER_IDS::SCHOOL, '__SCHOOL__'),
          # en_outro
        ],
        es: [
          genStory.call(st_no),
          genMessage.call(es_intro, USER_IDS::SCHOOL, '__SCHOOL__'),
          # es_outro
        ]
      },
    }

    user.state_table.update(story_number: st_no -1)
    return  msgs.to_json

  end

  # endpoints

  # at each endpoing
  # if fails auth jwt
  #   redirect to AuthApi

end
