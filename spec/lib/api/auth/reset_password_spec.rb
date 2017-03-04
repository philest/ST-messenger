require 'spec_helper'
require 'bot/dsl'
require 'bot/curricula'
require 'timecop'
require 'workers'
require 'api/reset_password'
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
    ResetPassword
  end


  context 'resetting password w phone', forget_password: true do
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



    describe '/phone/sms' do
      it 'fails when phone is not in db' do

        # TextingWorker_double = class_double("TextingWorker")
        # allow(TextingWorker_double).to receive(:perform_async) { nil }

        post '/phone/sms', { phone: "random_fake_phone_number" }

        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::PHONE_NOT_FOUND
        # obvs expect the user not to be updated in db... but if somethings wonky, don't take it for granted

      end
    end









    describe '/phone/code' do
      it 'fails when missing phone or random_code' do
        post '/phone/code', { token: "this could theoretically be a real token, but it's not" }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        post '/phone/code', { randomCode: @random_code }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        post '/phone/code', { }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

      end




      it 'fails when token is invalid' do
        post '/phone/code', { token: "this is a garbage token", randomCode: @random_code }
        res = JSON.parse(last_response.body)

        puts res["title"]
        expect(res["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
      end




      it 'fails when token is invalid' do
        post '/phone/code', { token: "this is a garbage token", randomCode: @random_code }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
      end



      it 'fails when user was destroyed...' do
        real_jwt = forgot_password_encode(@user.id, @now, @now + @life_length, @random_code)

        @user.destroy

        post '/phone/code', { token: real_jwt, randomCode: @random_code }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::USER_NOT_EXIST

      end
    end






    describe '/phone/reset' do
      it 'fails when missing phone or password' do
        post '/phone/reset', { token: "this could theoretically be a real token, but it's not" }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        post '/phone/reset', { password: @new_password }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING

        post '/phone/reset', { }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::CREDENTIALS_MISSING
      end



      it 'fails when token is invalid' do
        post '/phone/reset', { token: "this is a garbage token", password: @new_password }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
      end




      it 'fails when token is invalid' do
        post '/phone/reset', { token: "this is a garbage token", password: @new_password }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::TOKEN_CORRUPT
      end




      it 'fails when user was destroyed...' do
        real_jwt = forgot_password_encode(@user.id, @now, @now + @life_length, @random_code)

        @user.destroy

        post '/phone/reset', { token: real_jwt, password: @new_password }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::USER_NOT_EXIST

      end
    end









    describe 'full flow', flow: true do
      it 'succeeds when done well, also (just) about to expire', forget_succeed: true do
        # step 1: user requests a password reset
        post '/phone/sms', { phone: @phone }


        # if (JSON.parse(last_response.body)["title"])
        #   puts JSON.parse(last_response.body)["title"]
        #   puts JSON.parse(last_response.body)["code"]
        # end
        expect(last_response.status).to eq 201

        access_tkn = JSON.parse(last_response.body)["token"]


        Timecop.freeze(@time + @life - 1.second)

        #
        # ... user checks phone for random code
        #
        # step 2: user sends random code and access tkn
        post '/phone/code', { randomCode: @random_code, token: access_tkn }

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
        post '/phone/reset', { password: @new_password, token: refresh_tkn }
        expect(last_response.status).to eq 201

        expect(@user.password_digest).to_not eq(User.where(phone: @phone).first.password_digest)

      end






      it 'fails when wrong code', fail: true do
        # step 1: user requests a password reset
        post '/phone/sms', { phone: @phone }


        # if (JSON.parse(last_response.body)["title"])
        #   puts JSON.parse(last_response.body)["title"]
        #   puts JSON.parse(last_response.body)["code"]
        # end
        expect(last_response.status).to eq 201

        access_tkn = JSON.parse(last_response.body)["token"]
        wrong_code = "ESFSEE"

        Timecop.freeze(@time + @life - 1.second)

        #
        # ... user checks phone for random code
        #
        # step 2: user sends random code and access tkn
        post '/phone/code', { randomCode: wrong_code, token: access_tkn }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::SMS_CODE_WRONG
        post '/phone/code', { randomCode: "#{@random_code}2", token: access_tkn }
        res = JSON.parse(last_response.body)
        expect(res["code"]).to eq STATUS_CODES::SMS_CODE_WRONG


      end




      it 'fails if too much time passed between step 1 and 2' do
        # request an SMS code


        # step 1: user requests a password reset
        post '/phone/sms', { phone: @phone }

        expect(last_response.status).to eq 201

        access_tkn = JSON.parse(last_response.body)["token"]


        Timecop.freeze(@time + @life + 1.second)

        #
        # ... user checks phone for random code
        #
        # step 2: user sends random code and access tkn
        post '/phone/code', { randomCode: @random_code, token: access_tkn }

        res = JSON.parse(last_response.body)
        expect(res['code']).to eq STATUS_CODES::TOKEN_EXPIRED
      end




      it 'fails if too much time between steps 2 and 3' do
        # request an SMS code


        # step 1: user requests a password reset
        post '/phone/sms', { phone: @phone }

        expect(last_response.status).to eq 201

        access_tkn = JSON.parse(last_response.body)["token"]


        Timecop.freeze(@time + @life - 1.second)


        #
        # ... user checks phone for random code
        #
        # step 2: user sends random code and access tkn
        post '/phone/code', { randomCode: @random_code, token: access_tkn }

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
          post '/phone/reset', { password: @new_password, token: refresh_tkn }
         }.not_to change{User.where(phone: @phone).first.password_digest}

        res = JSON.parse(last_response.body)
        expect(res['code']).to eq STATUS_CODES::TOKEN_EXPIRED
      end
    end
  end
end