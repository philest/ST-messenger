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


  context '/check_username', check_username:true do
    # note that the db is empty by default
    before(:all) do
      @valid_user_name = proc { |s| s == 204 || s == 420 }
    end

    it 'allows correct phone numbers' do
      post '/check_username', { username: "3013328953" }
      expect(last_response.status).to satisfy &@valid_user_name


      post '/check_username', { username: "1313131313" }
      expect(last_response.status).to satisfy &@valid_user_name

      post '/check_username', { username: "0000000000" }
      expect(last_response.status).to satisfy &@valid_user_name

    end

    it 'allows correct emails' do
      post '/check_username', { username: "aawahl@gmail.com" }
      expect(last_response.status).to satisfy &@valid_user_name


      post '/check_username', { username: "aawahl-test@gmail.com" }
      expect(last_response.status).to satisfy &@valid_user_name

      post '/check_username', { username: "aawahl@pe.poop.zip" }
      expect(last_response.status).to satisfy &@valid_user_name

    end

    it 'does not allow incorrect phone numbers' do
      # too small
      post '/check_username', { username: "301338953" }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID

      # too big
      post '/check_username', { username: "30133895322" }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID

      # whuttt
      post '/check_username', { username: "3013389asdfasd" }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID


      post '/check_username', { username: "1" }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID
    end

    it 'does not allow incorrect emails' do
      # too small
      post '/check_username', { username: "aawahl" }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID

      # too big
      post '/check_username', { username: "aawahl@" }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID

      # whuttt
      post '/check_username', { username: "a@a" }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID


      post '/check_username', { username: "aawahl@pee." }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID
    end

    it 'fails when credentials are empty' do

      post '/check_username', { username: "" }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

      post '/check_username', { username: nil }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

      post '/check_username', { }
      res = JSON.parse(last_response.body)
      expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING
    end

    describe '/check_phone redirect' do
      it 'fails when credentials are empty' do

        get '/check_phone', { phone: "" }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        get '/check_phone', { phone: nil }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        get '/check_phone', { }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING
      end

      it 'succeeds when correct phone format' do

        get '/check_phone', { phone: "3013328953" }
        expect(last_response.status).to satisfy &@valid_user_name

      end

    end

  end


  context "phone-email class methods", phoneEmail: true do

      context "emails" do
        it "rejects invalid emails" do
          string = "david"
          expect(string.is_email?).to eq false

          string = "david.com"
          expect(string.is_email?).to eq false

          string = "david@"
          expect(string.is_email?).to eq false

          string = "david@gmail"
          expect(string.is_email?).to eq false

          string = "david@gmail.c3292"
          expect(string.is_email?).to eq false

          string = "david.mcpeek@yale.company_that_is_mine"
          expect(string.is_email?).to eq false

          string = "david.mc----peek@y4343ale.edu"
          expect(string.is_email?).to eq true

        end

        it "accepts valid emails" do
          string = "david.mcpeek@yale.edu"
          expect(string.is_email?).to eq true

          string = "david.mcpeek@y4343ale.edu"
          expect(string.is_email?).to eq true

          string = "david.mcpeek@yale.companythatismine"
          expect(string.is_email?).to eq true

        end

      end


      context "phone numbers" do
        it "rejects invalid phone numbers" do
          string = "david.mcpeek@yale.edu"
          expect(string.is_phone?).to eq false

          string = "12345abcd"
          expect(string.is_phone?).to eq false

          string = "(818)689-7323"
          expect(string.is_phone?).to eq false

          string = "098422       "
          expect(string.is_phone?).to eq false

          string = "1"
          expect(string.is_phone?).to eq false
        end

        it "accepts valid phone numbers" do
          string = "8186897323"
          expect(string.is_phone?).to eq true
        end

      end

  end




  context 'signing up with username', signupUsername:true do
    before(:each) do
      @teacher = Teacher.create(signature: "Ms. Teacher", email: "teacher@school.edu")
      @school  = School.create(signature: "School", name: "School", code: "school|school-es")
      @school.signup_teacher(@teacher)

    end

    it "adds username to `email` field when email format" do
      username = 'david.mcpeek@yale.edu'
      post '/signup', {username:username, first_name: 'David', last_name: 'McPeek', password: 'my_password', class_code: 'school1'}
      emailUser = User.where(email: username).first
      phoneUser = User.where(phone: username).first

      expect(emailUser).to_not be_nil
      expect(phoneUser).to be_nil
    end

    it "adds username to `phone` field when phone format" do
      username = '8186897323'
      post '/signup', {username:username, first_name: 'David', last_name: 'McPeek', password: 'my_password', class_code: 'school1'}
      emailUser = User.where(email: username).first
      phoneUser = User.where(phone: username).first

      expect(emailUser).to be_nil
      expect(phoneUser).to_not be_nil
    end

    it "fails to sign up a user when username is an invalid email and phone" do
      username = 'an invalid-ass username.gov'
      post '/signup', {username:username, first_name: 'David', last_name: 'McPeek', password: 'my_password', class_code: 'school1'}
      emailUser = User.where(email: username).first
      phoneUser = User.where(phone: username).first

      expect(emailUser).to be_nil
      expect(phoneUser).to be_nil
    end

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



















  context 'signing up user with registered teacher/school system', registered_user: true do
    before(:each) do
      # create school/teacher
      @teacher = Teacher.create(signature: "Ms. Teacher", email: "teacher@school.edu")
      @school  = School.create(signature: "School", name: "School", code: "school|school-es")
      @school.signup_teacher(@teacher)
      @phone = '8186897323'
    end

    it "returns NO_MATCHING_SCHOOL with wrong code" do
      body = {
        phone: @phone,
        first_name: 'David',
        last_name: 'McPeek',
        password: 'my_password',
        class_code: 'wrong-ass_code'
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
      class_code = @teacher.code.split('|')[0] # correct code
      body = {
        phone: @phone,
        first_name: 'David',
        last_name: 'McPeek',
        password: 'my_password',
        class_code: class_code
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
      expect(user.class_code).to eq class_code
    end


    it 'creates user with spanish' do
      body = {
        phone: @phone,
        first_name: 'David',
        last_name: 'McPeek',
        password: 'my_password',
        class_code: @teacher.code.split('|')[1], # correct code
        locale: 'es'
      }
      post '/signup', body

      expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
      user = User.where(phone: @phone).first
      expect(user).to_not be_nil

      expect(user.teacher.id).to eq @teacher.id
      expect(user.school.id).to eq @school.id
      expect(user.locale).to eq 'es'
      expect(user.password_digest).to_not be_nil # todo: make this test again b
      expect(user.first_name).to eq 'David'
      expect(user.last_name).to eq 'McPeek'
    end
  end









  context 'signing up free-agent', free_agent: true do
    before(:each) do
      # note: no need to create school. the system should automatically create if missing.
      @phone = "3013328953"
      @email = "aawahl@gmail.com"
      @bad_email = "a"
    end

    describe "succesful freeagent signup when" do
      it "agent fills out everything", poop:true do
        post '/signup_free_agent', {
          phone: @phone,
          first_name: 'Aubrey',
          last_name: 'Wahl',
          password: 'my_password',
          locale: 'en',
        }
        expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
        expect(User.all.size).to eq(1)
        expect(User.first.class_code).to eq('freeagent1')
      end

      it "agent signs up in spanish" do
        post '/signup_free_agent', {
          phone: @phone,
          first_name: 'Aubrey',
          last_name: 'Wahl',
          password: 'my_password',
          locale: 'es',
        }
        expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
        expect(User.all.size).to eq(1)
        expect(User.first.class_code).to eq('freeagent-es1')
      end
    end

    describe "when school and teacher already exist" do
      before(:each) do
        @school_code_base = 'freeagent' # NOTE: gotta make sure this matches up with api/auth.rb
        school_code_expression = "#{@school_code_base}|#{@school_code_base}-es"
        SIGNUP::create_free_agent_school(School, Teacher, school_code_expression)
      end


      it "agent fills out everything (legacy)" do
        post '/signup_free_agent', {
          phone: @phone,
          first_name: 'Aubrey',
          last_name: 'Wahl',
          password: 'my_password',
          locale: 'en',
        }
        expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
        expect(User.all.size).to eq(1)
        expect(User.first.class_code).to eq("#{@school_code_base}1")
      end

      it "agent fills out everything" do
        post '/signup_free_agent', {
          username: @email,
          first_name: 'Aubrey',
          last_name: 'Wahl',
          password: 'my_password',
          locale: 'en',
        }
        expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
        expect(User.all.size).to eq(1)
        expect(User.first.class_code).to eq("#{@school_code_base}1")

        post '/signup_free_agent', {
          username: @phone,
          first_name: 'Aubrey',
          last_name: 'Wahl',
          password: 'my_password',
          locale: 'en',
        }
        expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
        expect(User.all.size).to eq(2)
        expect(User.first.class_code).to eq("#{@school_code_base}1")
      end


      it "agent signs up in spanish" do
        post '/signup_free_agent', {
          phone: @phone,
          first_name: 'Aubrey',
          last_name: 'Wahl',
          password: 'my_password',
          locale: 'es',
        }
        expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
        expect(User.all.size).to eq(1)
        expect(User.first.class_code).to eq("#{@school_code_base}-es1")
      end
    end

    describe "errs when" do
      it "missing phone (legacy)" do
        post '/signup_free_agent', {
          first_name: 'David',
          last_name: 'McPeek',
          password: 'my_password',
          time_zone: -4.0,
        }
        # puts(last_response.inspect)
        expect(JSON.parse(last_response.body)['code']).to eq STATUS_CODES::MISSING_CREDENTIALS
      end
      it "missing first_name (legacy)" do
        post '/signup_free_agent', {
          phone: @phone,
          last_name: 'McPeek',
          password: 'my_password',
          time_zone: -4.0,
        }
        # puts(last_response.inspect)
        expect(JSON.parse(last_response.body)['code']).to eq STATUS_CODES::MISSING_CREDENTIALS

      end
      it "missing password (legacy)" do
        post '/signup_free_agent', {
          phone: @phone,
          first_name: 'David',
          last_name: 'McPeek',
          time_zone: -4.0,
        }
        expect(JSON.parse(last_response.body)['code']).to eq STATUS_CODES::MISSING_CREDENTIALS
      end

      it "poorly formatted phone" do
        post '/signup_free_agent', {
          username: "111222333",
          first_name: 'David',
          last_name: 'McPeek',
          time_zone: -4.0,
        }
        expect(JSON.parse(last_response.body)['code']).to eq STATUS_CODES::MISSING_CREDENTIALS
      end

      it "poorly formatted email" do
        post '/signup_free_agent', {
          username: @bad_email,
          first_name: 'David',
          last_name: 'McPeek',
          time_zone: -4.0,
        }
        expect(JSON.parse(last_response.body)['code']).to eq STATUS_CODES::MISSING_CREDENTIALS
      end

      it "doesn't create a user" do
        user = User.where(phone: @phone).first
        expect(user).to be_nil
      end
    end

    describe "succesful user creation when" do
      it "agent fills out everything" do
        post '/signup_free_agent', {
          phone: @phone,
          first_name: 'David',
          last_name: 'McPeek',
          time_zone: -4.0,
          password: 'just some passwoekre3892384(*#$&2'
        }
        expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
        expect(User.all.size).to eq(1)
        expect(User.first.class_code).to eq("freeagent1")
      end
    end
  end
end

















describe 'protected api', api: true do
  include Rack::Test::Methods
  include STATUS_CODES
  include AuthenticationHelpers
  include BCrypt

  def app
    UserAPI
  end

  before(:each) do
      # create school/teacher
      @teacher = Teacher.create(signature: "Ms. Teacher", email: "teacher@school.edu")
      @school  = School.create(signature: "School", name: "School", code: "school|school-es")
      @school.signup_teacher(@teacher)
      @phone = '8186897323'
      @user = User.create(phone: @phone, password_digest: BCrypt::Password.create('my_password'))
      @teacher.signup_user(@user)

      @refresh_tkn = refresh_token(@user.id)
      @access_tkn = access_token(@user.id)

      puts "REFRESH = #{@refresh_tkn}"
      puts "ACCESS = #{@access_tkn}"

      @user.update(refresh_token_digest: BCrypt::Password.create(@refresh_tkn))
  end

    # TODO some day :'-(

    # it 'can update users info' do
    #   body = {
    #     phone: @phone,
    #     first_name: 'David',
    #     last_name: 'McPeek',
    #     password: 'my_password',
    #     class_code: @teacher.code.split('|')[1], # correct code
    #     locale: 'es'
    #   }
    #   post '/signup', body

    #   expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS
    #   user = User.where(phone: @phone).first
    #   expect(user).to_not be_nil

    #   platform = 'android'
    #   fcm_token = 'test_tkn'
    #   app_version = '12 or whatever'

    #   post '/user_data', {
    #     platform: platform,
    #     fcm_token: fcm_token,
    #     app_version: app_version,
    #   }

    #   expect(last_response.status).to eq STATUS_CODES::CREATE_USER_SUCCESS


    # end



  # context 'the api endpoints' do

  #   it "tests", test:true do
  #     puts "ENV"
  #     get '/test', {}, {"HTTP_AUTHORIZATION"=>"Bearer: #{@access_tkn}"}
  #   end

  #   context "/chat_message" do
  #     it "does something" do
  #       get '/chat_message', {}, {"HTTP_AUTHORIZATION"=>"Bearer: #{@access_tkn}"}
  #     end

  #   end

  #   it "returns SUCCESS with valid access token" do

  #     options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
  #     # puts "auth = #{env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)}"

  #     # bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
  #     # puts "bearer = #{bearer}"
  #     # puts "ENV = #{ENV['JWT_ISSUER']} #{ENV['JWT_SECRET']}"
  #     payload, header = JWT.decode @access_tkn, ENV['JWT_SECRET'], true, options
  #     puts "TESSSSSSSSST = #{payload.inspect}"


  #     get '/test', {}, {"HTTP_AUTHORIZATION"=>"Bearer: #{@access_tkn}"}
  #     expect(last_response.status).to eq STATUS_CODES::SUCCESS
  #   end

  # end

  # context 'bad access token' do

  #   it "returns WRONG_TKN_TYPE it's a refresh token and not an access token", god:true do
  #     # get a refresh token
  #     # try to access
  #     x = get '/test', {}, {"HTTP_AUTHORIZATION"=>"Bearer: #{@refresh_tkn}"}
  #     puts "x = #{x.inspect}"
  #     expect(last_response.status).to eq STATUS_CODES::WRONG_ACCESS_TKN_TYPE
  #   end

  #   it "fails at every api endpoint with a bad access token" do
  #     get '/test', {}, {"HTTP_AUTHORIZATION"=>"Bearer: my_ass_is_an_access_token...i mean, maybe"}
  #     expect(last_response.status).to eq STATUS_CODES::NO_VALID_ACCESS_TKN
  #   end

  # end

end

