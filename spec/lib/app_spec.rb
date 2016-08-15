require 'spec_helper'
require 'app'
require 'timecop'
require 'active_support/time'
require 'workers'


describe SMS do
  include Rack::Test::Methods
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  def app
    SMS
  end

  before(:all) do
    @enroll_params = { 
      :name_0 => "Phil Esterman", :phone_0 => "5612125831",
      :name_1 => "David McPeek", :phone_1 => "8186897323",
      :name_2 => "Aubrey Wahl", :phone_2 => "3013328953",
      :teacher_signature => "McEsterWahl", :teacher_email => "david.mcpeek@yale.edu",
    }
  end

  context 'post /sms with new user', newuser:true do
    before(:each) do
      Sidekiq::Worker.clear_all
      allow(Pony).to(receive(:mail).with(hash_including(:to, :cc, :from, :headers, :body, :subject)))
      @sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"Please, you have to help me, I've been trapped in the Phantom Zone for centuries, there's not much tiiiiiiiiiiiiiiiiiiiiiiiiii.......", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+18186897323", "ApiVersion"=>"2010-04-01"}

      stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=Hi%21%20I%27m%20away%20now%2C%20but%20I%27ll%20see%20your%20message%20soon%21%20If%20you%20need%20help%20just%20enter%20%27learn%27",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})
    end

    it "adds a user to the db" do
      expect {
        post '/sms', @sms_params
      }.to change{User.count}.by 1
    end

    it "enqueues a texting job" do
      Sidekiq::Testing::fake! do
        expect {
          post '/sms', @sms_params

          # to change some other job, whatever it is....
        }.to change(MessageWorker.jobs, :size).by(1)
      end
    end

    it "does not message a pre-existing user with their first story" do
      user = User.create(phone: "8186897323")

      Sidekiq::Testing::fake! do
        expect {
          post '/sms', @sms_params
        }.to change(MessageWorker.jobs, :size).by(0)
      end

    end

    it "does not add a new user when they already exist" do
      user = User.create(phone: "8186897323")

      Sidekiq::Testing::fake! do
        expect {
          get '/sms', @sms_params
        }.to change{User.count}.by(0)
      end
    end
  end


end