require 'spec_helper'
require 'bot/dsl'
require 'bot/curricula'
require 'timecop'
require 'workers'
require 'api/auth'
require 'api/user'
require 'api/helpers/authentication'
require 'api/helpers/signup'
require 'api/constants/statusCodes'
require 'api/middleware/authorizeEndpoint'
require 'bcrypt'
require 'jwt'
require 'dotenv'


Dotenv.load

ENV['RACK_ENV'] = 'test'
require 'rack/test'

module JSONHelper
  def post_json(uri, json)
    return post uri, json, "CONTENT_TYPE" => "application/json"
  end
end

describe 'auth' do
  include Rack::Test::Methods
  include STATUS_CODES
  include BCrypt
  include JSONHelper
  include AuthenticationHelpers


  def app
    AuthAPI
  end




  context 'getting an access token' do
    before(:each) do
      # create school/teacher

      @teacher = Teacher.create(signature: "Ms. Teacher", email: "teacher@school.edu")
      @school  = School.create(signature: "School", name: "School", code: "school|school-es")
      @school.signup_teacher(@teacher)
      @phone = '8186897323'
      # @user = User.create(phone: @phone, password_digest: BCrypt::Password.create('my_password'))
      # @teacher.signup_user(@user)

      post '/signup', {phone:@phone, first_name: 'David', last_name: 'McPeek', password: 'my_password', class_code: 'school1'}

      @user = User.where(phone: @phone).first

      post '/login', {phone: @phone, password: 'my_password'}

      @token = JSON.parse(last_response.body)['token']

    end

    it "returns WRONG_ACCESS_TKN_TYPE when given an access token or something else", atoken:true do

      post '/get_access_tkn', {}, {'HTTP_AUTHORIZATION' => "Bearer #{@token}"}

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      # the bearer is the refresh_token
      access_tkn = JSON.parse(last_response.body)['token']


      access_tkn_payload, header = JWT.decode access_tkn, ENV['JWT_SECRET'], true, options

      user = access_tkn_payload['user']
      type = access_tkn_payload['type']

      post '/get_access_tkn', {}, {'HTTP_AUTHORIZATION' => "Bearer #{access_tkn}"}
      expect(last_response.status).to eq STATUS_CODES::WRONG_ACCESS_TKN_TYPE

     end

    it "returns a valid access token when refresh token is good" do
      post '/get_access_tkn', {}, {'HTTP_AUTHORIZATION' => "Bearer #{@token}"}

      token =  JSON.parse(last_response.body)['token']

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      # the bearer is the refresh_token

      access_tkn_payload, header = JWT.decode token, ENV['JWT_SECRET'], true, options


      user = access_tkn_payload['user']
      type = access_tkn_payload['type']

      expect(user['user_id']).to eq @user.id
      expect(type).to eq 'access'

    end

    it "returns error when invalid refresh token" do
      post '/get_access_tkn', {}, {'HTTP_AUTHORIZATION' => "Bearer my_ass_is_a_token"}
      expect(last_response.status).to eq 404
      expect(JSON.parse(last_response.body)["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
    end

    it "returns NO_EXISTING_USER when the user id is bad" do

    end

  end





  context 'logging in user' do
    before(:each) do
      # create school/teacher
      @teacher = Teacher.create(signature: "Ms. Teacher", email: "teacher@school.edu")
      @school  = School.create(signature: "School", name: "School", code: "school|school-es")
      @school.signup_teacher(@teacher)
      @phone = '8186897323'
      @password = 'my_password'
      @user = User.create(phone: @phone, password_digest: BCrypt::Password.create(@password))
      @teacher.signup_user(@user)
    end

    it "returns NO_EXISTING_USER when phone number is invalid" do
      invalid_phone = 'invalid_phone'
      user = User.create(phone: invalid_phone, password_digest: BCrypt::Password.create(@password))
      @teacher.signup_user(user)

      body = {  phone: invalid_phone, password: @password }

      post '/login', body
      expect(last_response.status).to eq STATUS_CODES::NO_EXISTING_USER


    end

    it "returns NO_EXISTING_USER when email  is invalid" do
      invalid_email = 'invalid_phone'
      user = User.create(email: invalid_email, password_digest: BCrypt::Password.create(@password))
      @teacher.signup_user(user)

      body = { phone: invalid_email, password: @password }

      post '/login', body
      expect(last_response.status).to eq STATUS_CODES::NO_EXISTING_USER

    end


    it "returns NO_EXISTING_USER when phone number is wrong" do
      wrong_number = 'my_ass'
      body = { phone: wrong_number, password: @password }
      post '/login', body

      expect(last_response.status).to eq STATUS_CODES::NO_EXISTING_USER
    end

    it "returns WRONG_PASSWORD when the password is incorrect" do
      wrong_password = 'my_ass'
      body = { phone: @phone, password: wrong_password }
      post '/login', body

      expect(last_response.status).to eq STATUS_CODES::WRONG_PASSWORD
    end

    it "returns MISSING_CREDENTIALS with missing creds" do
      post '/login'
      expect(last_response.status).to eq STATUS_CODES::MISSING_CREDENTIALS
    end


    it "returns valid refresh token with `username` in params body and it's a PHONE" do
      valid_phone = '9993331111'
      user = User.create(phone: valid_phone, password_digest: BCrypt::Password.create(@password))
      @teacher.signup_user(user)

      body = { username: valid_phone, password: @password }

      post '/login', body

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      # the bearer is the refresh_token
      token = JSON.parse(last_response.body)['token']

      payload, header = JWT.decode token, ENV['JWT_SECRET'], true, options

      the_user = payload['user']
      type = payload['type']

      expect(the_user['user_id']).to eq user.id
      expect(type).to eq 'refresh'
      user.reload

      expect(BCrypt::Password.new(user.refresh_token_digest).is_password? token).to eq true

      # check to see that the type is refresh
    end

    it "returns valid refresh token with `username` in params body and it's an EMAIL" do
      valid_email = 'david.mcpeek@yale.edu'
      user = User.create(email: valid_email, password_digest: BCrypt::Password.create(@password))
      @teacher.signup_user(user)

      body = { username: valid_email, password: @password }

      post '/login', body

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      # the bearer is the refresh_token
      token = JSON.parse(last_response.body)['token']

      payload, header = JWT.decode token, ENV['JWT_SECRET'], true, options

      the_user = payload['user']
      type = payload['type']

      expect(the_user['user_id']).to eq user.id
      expect(type).to eq 'refresh'
      user.reload

      expect(BCrypt::Password.new(user.refresh_token_digest).is_password? token).to eq true

      # check to see that the type is refresh
    end

    it "returns a dbuuid, refresh token, and user role" do
      valid_email = 'david.mcpeek@yale.edu'
      user = User.create(email: valid_email, password_digest: BCrypt::Password.create(@password), role: 'parent')
      @teacher.signup_user(user)

      body = { username: valid_email, password: @password }

      post '/login', body

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      # the bearer is the refresh_token
      token = JSON.parse(last_response.body)['token']

      payload, header = JWT.decode token, ENV['JWT_SECRET'], true, options

      the_user = payload['user']
      type = payload['type']

      expect(the_user['user_id']).to eq user.id
      expect(type).to eq 'refresh'
      user.reload

      expect(JSON.parse(last_response.body)).to include("role" => user.role, "dbuuid" => user.id )

      # check to see that the type is refresh
    end



    it "returns a valid refresh token and updates user with digest (with correct password)" do
      body = {
        phone: @phone,
        password: @password
      }

      post '/login', body

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      # the bearer is the refresh_token
      token = JSON.parse(last_response.body)['token']

      payload, header = JWT.decode token, ENV['JWT_SECRET'], true, options

      user = payload['user']
      type = payload['type']

      expect(user['user_id']).to eq @user.id
      expect(type).to eq 'refresh'
      @user.reload

      expect(BCrypt::Password.new(@user.refresh_token_digest).is_password? token).to eq true

      # check to see that the type is refresh
    end

  end


end


