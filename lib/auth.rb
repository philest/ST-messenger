#  app.rb                                     David McPeek      
# 
#  The routes controller. Recieves POST from 
#  www.joinstorytime.com/enroll with family phones and names. 
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

class AuthApi < Sinatra::Base
  include ContactHelpers
  include MessageReplyHelpers
  include TwilioTextingHelpers
  include NameCodes

  use Airbrake::Rack::Middleware

  set :session_secret, "328479283uf923fu8932fu923uf9832f23f232"
  enable :sessions

  set :root, File.join(File.dirname(__FILE__), '../')

  helpers Authentication
  helpers SchoolCodeMatcher

  helpers do
    def redirect_to_original_request
      user = session[:user]
      flash[:notice] = "Welcome back #{user.name}."
      original_request = session[:original_request]
      session[:original_request] = nil
      redirect original_request
    end
  end

  before do
    headers 'Content-Type' => 'text/html; charset=utf-8'
  end

  post '/signup/?' do
    phone       = params[:phone_no]
    first_name  = params[:first_name]
    last_name   = params[:last_name]
    password    = params[:password]
    code        = params[:code].delete(' ').delete('-').downcase

    if is_matching_code?(code) then
      new_user = User.create(phone: phone, first_name: first_name, last_name: last_name, platform: 'app')
      new_user.set_password(password)
      # associate school/teacher, whichever
      new_user.match_school(code)
      new_user.match_teacher(code)

      # now do session stuff....
      # what should we store in session variable?
      session[:user] = new_user.id

      # WHAT DO WE RETURN HERE?
      redirect "SUCCESS!!!!!!!!!!"

    else # no matching code, don't sign this user up.
      # basically, this condition is how we differentiate between paying customers and randos

      return 404 # or something

    end

  end

  # post/get with signin? 
  # where do we redirect? 

  post '/signin/?' do
    phone       = params[:phone_no]
    password    = params[:password]

    user = User.where(phone: phone).first
    if user.nil?
      return 404
    end

    if user.authenticate(password) == true
      session[:user] = user.id
      redirect_to_original_request
    end

    if user = User.authenticate(params)
      session[:user] = user
      redirect_to_original_request
    else
      flash[:notice] = 'You could not be signed in. Did you enter the correct username and password?'
      redirect '/signin'
    end
  end

  # note: everything redirects to signin! if we don't authenticate

  get '/signin' do


  end


  get '/signout' do
    session[:user] = nil
    return 200
  end

  get '/user_info' do
    case authenticate!
    when 200
      return "the user info"
      # params[:id], whatnot
    else
      return 401
    end
  end


end























