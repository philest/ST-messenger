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
require 'rack/test'




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

