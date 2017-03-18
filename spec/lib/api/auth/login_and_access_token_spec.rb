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



describe 'auth' do
  include Rack::Test::Methods
  include STATUS_CODES
  include BCrypt
  include AuthenticationHelpers


  def app
    AuthAPI
  end


  context '/check_username', check_username:true do
    # note that the db is empty by default
    before(:all) do
      @valid_user_name = proc { |s| s == 204 || s == 420 }
    end

    it 'is case-insenstive' do
      base_email = "aawahl@gmail.com"
      variant1 = "AAWAHL@gmail.COM"
      variant2 = "aawAhl@gmail.Com"
      post '/signup_free_agent', {username:base_email, first_name: 'David', last_name: 'McPeek', password: 'my_password', class_code: 'school1'}
      expect(last_response.status).to eq 201

      post '/check_username', { username: base_email }
      expect(last_response.status).to satisfy &@valid_user_name
      post '/check_username', { username: variant1 }
      expect(last_response.status).to satisfy &@valid_user_name
      post '/check_username', { username: variant2 }
      expect(last_response.status).to satisfy &@valid_user_name


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


  describe '/login' do
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

    describe 'input error:' do
      it "returns NO_EXISTING_USER when phone number is invalid" do
        invalid_phone = 'invalid_phone'
        user = User.create(phone: invalid_phone, password_digest: BCrypt::Password.create(@password))
        @teacher.signup_user(user)

        body = {  phone: invalid_phone, password: @password }

        post '/login', body
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::USER_NOT_EXIST


      end

      it "returns NO_EXISTING_USER when email  is invalid" do
        invalid_email = 'invalid_phone'
        user = User.create(email: invalid_email, password_digest: BCrypt::Password.create(@password))
        @teacher.signup_user(user)

        body = { phone: invalid_email, password: @password }

        post '/login', body
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::USER_NOT_EXIST

      end


      it "returns NO_EXISTING_USER when phone number is wrong" do
        wrong_number = 'my_ass'
        body = { phone: wrong_number, password: @password }
        post '/login', body

        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::USER_NOT_EXIST
      end


      it "returns CREDENTIALS_INVALID when the password is incorrect" do
        wrong_password = 'my_ass'
        body = { phone: @phone, password: wrong_password }
        post '/login', body

        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_INVALID
      end


      it "returns CREDENTIALS_MISSING with missing creds" do
        post '/login'

        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING
      end
    end

    describe 'succesful login flow:' do

      describe "refresh token", refresh_token_gen: true do
        before(:each) do
          @good_phone = '9993331111'
          @good_user = User.create(phone: @good_phone, password_digest: BCrypt::Password.create(@password))
          @teacher.signup_user(@good_user)
          @good_body = { username: @good_phone, password: @password }
          @now = Time.now
          @leq_six_months = Time.now + 6.months - 1.day
          @geq_six_months = Time.now + 6.months + 1.day

        end

        it "created if none existed before" do
          expect {
            post '/login', @good_body
          }.to change{ User.where(phone: @good_phone).first.refresh_token_digest }
        end

        it "does not change if user logs in within 6 months" do
          post '/login', @good_body
          Timecop.freeze(@leq_six_months)
          expect {
            post '/login', @good_body
          }.not_to change{ User.where(phone: @good_phone).first.refresh_token_digest }
          Timecop.return
        end

        it "issues anew if user logs in after 6 months" do
          Timecop.freeze
          post '/login', @good_body
          expect(User.where(phone: @good_phone).first.last_refresh_token_iss).to eq Time.now.utc

          Timecop.freeze(@geq_six_months)
          expect {
            post '/login', @good_body
          }.to change{ User.where(phone: @good_phone).first.refresh_token_digest }
          expect(User.where(phone: @good_phone).first.last_refresh_token_iss).to eq @geq_six_months.utc

          Timecop.return
        end

        it ", issues error if token creation somehow fails" 
      end


      it "returns valid refresh token with `username` in params body and it's a PHONE" do
        valid_phone = '3013328953'
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

end













