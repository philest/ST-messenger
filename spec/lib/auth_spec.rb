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
      @phone = 'sample_phone_number'
      # @user = User.create(phone: @phone, password_digest: BCrypt::Password.create('my_password'))
      # @teacher.signup_user(@user)

      post '/signup', {phone:@phone, first_name: 'David', last_name: 'McPeek', password: 'my_password', class_code: 'school1'}

      @user = User.where(phone: @phone).first

      post '/login', {phone: @phone, password: 'my_password'}

      @token = JSON.parse(last_response.body)['token']

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









  context 'resetting password', forget_password: true do
    before(:each) do
      # create school/teacher
      @teacher = Teacher.create(signature: "Ms. Teacher", email: "teacher@school.edu")
      @school  = School.create(signature: "Da Skool", name: "School", code: "school|school-es")
      @school.signup_teacher(@teacher)
      @phone = '3013328953'
      @password = 'my_password'
      @user = User.create(phone: @phone, password_digest: BCrypt::Password.create(@password))
      @teacher.signup_user(@user)
      @new_password = "the new password"

      @time = Time.new(2017, 2, 15, 19, 0, 0, 0) # with 0 utc-offset

      Timecop.freeze(@time)


      @now = Time.now.to_i
      @life = 5.minutes
      @life_length = @life.to_i
      srand(1)
      @random_code = 4.times.map{rand(10)}.join
      srand(1)


    end
    after(:each) { Timecop.return }



    describe '/forgot_password_phone' do
      it 'fails when phone is not in db' do

        # TextingWorker_double = class_double("TextingWorker")
        # allow(TextingWorker_double).to receive(:perform_async) { nil }

        post '/forgot_password_phone', { phone: "random_fake_phone_number" }

        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::PHONE_NOT_FOUND
        # obvs expect the user not to be updated in db... but if somethings wonky, don't take it for granted

      end
    end









    describe '/forgot_password_phone_code' do
      it 'fails when missing phone or random_code' do
        post '/forgot_password_phone_code', { token: "this could theoretically be a real token, but it's not" }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        post '/forgot_password_phone_code', { randomCode: @random_code }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        post '/forgot_password_phone_code', { }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

      end




      it 'fails when token is invalid' do
        post '/forgot_password_phone_code', { token: "this is a garbage token", randomCode: @random_code }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
      end




      it 'fails when token is invalid' do
        post '/forgot_password_phone_code', { token: "this is a garbage token", randomCode: @random_code }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
      end



      it 'fails when user was destroyed...' do
        real_jwt = forgot_password_encode(@user.id, @now, @now + @life_length, @random_code)

        @user.destroy

        post '/forgot_password_phone_code', { token: real_jwt, randomCode: @random_code }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::USER_NOT_EXIST

      end
    end






    describe '/reset_password_phone' do
      it 'fails when missing phone or password' do
        post '/reset_password_phone', { token: "this could theoretically be a real token, but it's not" }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        post '/reset_password_phone', { password: @new_password }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        post '/reset_password_phone', { }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING
      end



      it 'fails when token is invalid' do
        post '/reset_password_phone', { token: "this is a garbage token", password: @new_password }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
      end




      it 'fails when token is invalid' do
        post '/reset_password_phone', { token: "this is a garbage token", password: @new_password }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
      end




      it 'fails when user was destroyed...' do
        real_jwt = forgot_password_encode(@user.id, @now, @now + @life_length, @random_code)

        @user.destroy

        post '/reset_password_phone', { token: real_jwt, password: @new_password }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::USER_NOT_EXIST

      end
    end









    describe 'full flow', flow: true do
      it 'succeeds when done well, also (just) about to expire', forget_succeed: true do
        # step 1: user requests a password reset
        post '/forgot_password_phone', { phone: @phone }

        expect(last_response.status).to eq 201

        access_tkn = JSON.parse(last_response.body)["token"]


        Timecop.freeze(@time + @life - 1.second)

        #
        # ... user checks phone for random code
        #
        # step 2: user sends random code and access tkn
        post '/forgot_password_phone_code', { randomCode: @random_code, token: access_tkn }

        if (JSON.parse(last_response.body)["title"])
          puts JSON.parse(last_response.body)["title"]
          puts JSON.parse(last_response.body)["code"]
        end

        expect(last_response.status).to eq 200
        refresh_tkn = JSON.parse(last_response.body)["token"]


        #
        # ... user enters new password
        #
        # step 3: user sends in new password with refresh tkn
        expect {
          post '/reset_password_phone', { password: @new_password, token: refresh_tkn }
         }.to change{User.where(phone: @phone).first.password_digest}

         expect(last_response.status).to eq 201
      end




      it 'fails if too much time passed between step 1 and 2' do
        # request an SMS code


        # step 1: user requests a password reset
        post '/forgot_password_phone', { phone: @phone }

        expect(last_response.status).to eq 201

        access_tkn = JSON.parse(last_response.body)["token"]


        Timecop.freeze(@time + @life + 1.second)

        #
        # ... user checks phone for random code
        #
        # step 2: user sends random code and access tkn
        post '/forgot_password_phone_code', { randomCode: @random_code, token: access_tkn }

        res = JSON.parse(last_response.body)
        expect(res['code']).to eq STATUS_CODES::TOKEN_EXPIRED
      end




      it 'fails if too much time between steps 2 and 3' do
        # request an SMS code


        # step 1: user requests a password reset
        post '/forgot_password_phone', { phone: @phone }

        expect(last_response.status).to eq 201

        access_tkn = JSON.parse(last_response.body)["token"]


        Timecop.freeze(@time + @life - 1.second)


        #
        # ... user checks phone for random code
        #
        # step 2: user sends random code and access tkn
        post '/forgot_password_phone_code', { randomCode: @random_code, token: access_tkn }

        # if (JSON.parse(last_response.body)["title"])
        #   puts JSON.parse(last_response.body)["title"]
        #   puts JSON.parse(last_response.body)["code"]
        # end

        expect(last_response.status).to eq 200
        refresh_tkn = JSON.parse(last_response.body)["token"]

        Timecop.freeze(@time + @life + 1.second)


        #
        # ... user enters new password
        #
        # step 3: user sends in new password with refresh tkn
        expect {
          post '/reset_password_phone', { password: @new_password, token: refresh_tkn }
         }.not_to change{User.where(phone: @phone).first.password_digest}

        res = JSON.parse(last_response.body)
        expect(res['code']).to eq STATUS_CODES::TOKEN_EXPIRED
      end
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



















  context 'signing up user with registered teacher/school system', registered_user: true do
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


      it "agent fills out everything" do
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

    describe "errs when missing" do
      it "phone" do
        post '/signup_free_agent', {
          first_name: 'David',
          last_name: 'McPeek',
          password: 'my_password',
          time_zone: -4.0,
        }
        # puts(last_response.inspect)
        expect(JSON.parse(last_response.body)['code']).to eq STATUS_CODES::MISSING_CREDENTIALS
      end
      it "first_name" do
        post '/signup_free_agent', {
          phone: @phone,
          last_name: 'McPeek',
          password: 'my_password',
          time_zone: -4.0,
        }
        # puts(last_response.inspect)
        expect(JSON.parse(last_response.body)['code']).to eq STATUS_CODES::MISSING_CREDENTIALS

      end
      it "password" do
        post '/signup_free_agent', {
          phone: @phone,
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
      @phone = 'sample_phone_number'
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

