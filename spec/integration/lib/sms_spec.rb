require 'spec_helper'
require 'rack/test'
require 'timecop'
require 'active_support/time'
require 'app'


require 'bot'

describe 'sms' do
  include Rack::Test::Methods
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  def app
    SMS 
  end


  context 'multi-day test' do
    before(:all) do
      # load scripts
      Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_sms_scripts/*")
         .each {|f| require_relative f }

      @day1 = Birdv::DSL::ScriptClient.scripts['sms']["day1"]
      @day2 = Birdv::DSL::ScriptClient.scripts['sms']["day2"]
      @day3 = Birdv::DSL::ScriptClient.scripts['sms']["day3"]


      # a user texts in
      Sidekiq::Worker.clear_all
      

      @sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"Please, you have to help me, I've been trapped in the Phantom Zone for centuries, there's not much tiiiiiiiiiiiiiiiiiiiiiiiiii.......", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+18186897323", "ApiVersion"=>"2010-04-01"}
      @enroll_params = { :name_1 => "Phil Esterman", :phone_1 => "5612125831",
                         :teacher_signature => "McEsterWahl", :teacher_email => "david.mcpeek@yale.edu"
      }



    end

    before(:each) { allow(Pony).to(receive(:mail).with(hash_including(:to, :cc, :from, :headers, :body, :subject))) }

    before(:each) do
      post '/sms', @sms_params
      post '/', @enroll_params


      @u1 = User.where(phone: '8186897323').first
      @u2 = User.where(phone: '5612125831').first
      puts @u1.inspect, @u2.inspect
    end

    it 'added the users to the db correctly' do
      expect(@u1).to_not be_nil
      expect(@u2).to_not be_nil
    end

    it 'sends day1 to new user' do
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"Please, you have to help me, I've been trapped in the Phantom Zone for centuries, there's not much tiiiiiiiiiiiiiiiiiiiiiiiiii.......", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+15555555555", "ApiVersion"=>"2010-04-01"}
      # expect(@day1).to receive(:run_sequence).with('5555555555', 'firstmessage')

      expect(MessageWorker)
      Sidekiq::Testing.inline! do
        post '/sms', sms_params
      end
        
    end


    it 'sends day1 to @u1 but not @u2 at 4pm' do
      # expect(@day1).to receive(:run_sequence).with('8186897323', 'firstmessage')

      
      # Timecop.freeze(Time.new(2016, 6, 22, 16, 0, 0, 0))

      # expect()


    end





  end




end