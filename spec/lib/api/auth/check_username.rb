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

end

