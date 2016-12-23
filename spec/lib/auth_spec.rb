require 'spec_helper'
require 'bot/dsl'
require 'bot/curricula'
require 'timecop'
require 'workers'
require 'auth'
require 'helpers/authentication'
require 'bcrypt'
require 'jwt'
require 'dotenv'
Dotenv.load

ENV['RACK_ENV'] = 'test'
require 'rack/test'


describe 'auth' do
  include Rack::Test::Methods
  include STATUS_CODES
  include BCrypt


  def app
    AuthApi
  end

  context 'getting an access token' do
    before(:each) do
      # create school/teacher
      @teacher = Teacher.create(signature: "Ms. Teacher", email: "teacher@school.edu")
      @school  = School.create(signature: "School", name: "School", code: "school|school-es")
      @school.signup_teacher(@teacher)
      @phone = 'sample_phone_number'
      # @user = User.create(phone: @phone, password_digest: BCrypt::Password.create('my_password'))
      # @teacher.signup_user(@user)

      post '/signup', {phone:@phone, first_name: 'David', last_name: 'McPeek', password: 'my_password', code: 'school1'}

      @user = User.where(phone: @phone).first
      puts "@user = #{@user.inspect}"

      post '/login', {phone: @phone, password: 'my_password'}

      @token = JSON.parse(last_response.body)['token']

      puts "@token = #{@token.inspect}"

    end

    it "returns WRONG_ACCESS_TKN_TYPE when given an access token or something else" do 
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

      puts "FINAL TOKEN = #{access_tkn_payload.inspect}"

      
      user = access_tkn_payload['user']
      type = access_tkn_payload['type']

      expect(user['user_id']).to eq @user.id
      expect(type).to eq 'access'

    end

    it "returns error when invalid refresh token" do
      post '/get_access_tkn', {}, {'HTTP_AUTHORIZATION' => "Bearer my_ass_is_a_token"} 
      expect(last_response.status).to eq STATUS_CODES::NO_VALID_ACCESS_TKN
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
      @phone = 'sample_phone_number'
      @password = 'my_password'
      @user = User.create(phone: @phone, password_digest: BCrypt::Password.create(@password))
      @teacher.signup_user(@user)
    end

    it "returns NO_EXISTING_USER when phone number is wrong" do
      wrong_number = 'my_ass'
      body = {
        phone: wrong_number,
        password: @password
      }
      post '/login', body

      expect(last_response.status).to eq STATUS_CODES::NO_EXISTING_USER
    end

    it "returns WRONG_PASSWORD when the password is incorrect" do
      wrong_password = 'my_ass'
      body = {
        phone: @phone,
        password: wrong_password
      }
      post '/login', body

      expect(last_response.status).to eq STATUS_CODES::WRONG_PASSWORD
    end

    it "returns MISSING_CREDENTIALS with missing creds" do
      post '/login'
      expect(last_response.status).to eq STATUS_CODES::MISSING_CREDENTIALS
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

  context 'signing up user' do
    before(:each) do
      # create school/teacher
      @teacher = Teacher.create(signature: "Ms. Teacher", email: "teacher@school.edu")
      @school  = School.create(signature: "School", name: "School", code: "school|school-es")
      @school.signup_teacher(@teacher)
      @phone = 'my_phone'
    end

    it "returns NO_MATCHING_SCHOOL with wrong code" do
      body = {
        phone: @phone,
        first_name: 'David',
        last_name: 'McPeek',
        password: 'my_password',
        code: 'wrong-ass_code'
      }
      post '/signup', body

      expect(last_response.status).to eq STATUS_CODES::NO_MATCHING_SCHOOL
      user = User.where(phone: @phone).first
      expect(user).to be_nil
    end

    it "returns MISSING_CREDENTIALS with missing creds" do
      puts "STATUS_CODES = #{STATUS_CODES}"
      post '/signup'
      expect(last_response.status).to eq STATUS_CODES::MISSING_CREDENTIALS
    end

    it "creates a user with correct password_digest, locale, school, teacher, info" do
      body = {
        phone: @phone,
        first_name: 'David',
        last_name: 'McPeek',
        password: 'my_password',
        code: @teacher.code.split('|')[0] # correct code
      }
      post '/signup', body

      expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
      user = User.where(phone: @phone).first
      expect(user).to_not be_nil

      expect(user.teacher.id).to eq @teacher.id
      expect(user.school.id).to eq @school.id
      expect(user.locale).to eq 'en'
      expect(user.password_digest).to_not be_nil
      expect(user.first_name).to eq 'David'
      expect(user.last_name).to eq 'McPeek'
    end

    it 'creates user with spanish' do
      body = {
        phone: @phone,
        first_name: 'David',
        last_name: 'McPeek',
        password: 'my_password',
        code: @teacher.code.split('|')[1] # correct code
      }
      post '/signup', body

      expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
      user = User.where(phone: @phone).first
      expect(user).to_not be_nil

      expect(user.teacher.id).to eq @teacher.id
      expect(user.school.id).to eq @school.id
      expect(user.locale).to eq 'es'
      expect(user.password_digest).to_not be_nil
      expect(user.first_name).to eq 'David'
      expect(user.last_name).to eq 'McPeek'
    end

  end



end