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

