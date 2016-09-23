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

      allow_any_instance_of(SMS).to  receive(:sms).and_wrap_original do |original_method, *args|
        puts "stubbing SMS with #{args}"
      end

      allow_any_instance_of(SMS).to  receive(:mms).and_wrap_original do |original_method, *args|
        puts "stubbing MMS with #{args}"
      end

    end

    it "adds a user to the db" do
      expect {
        post '/sms', @sms_params
      }.to change{User.count}.by 1
    end

    context "matching users with schools" do
      before(:each) do
        @school = School.create(code: "turkey|turquia", signature: "the Turkey Farm", name: "TurkeyZilla")
        @school_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"TURKEY", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+18186897323", "ApiVersion"=>"2010-04-01"}
        @school_params_espanish = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"TURQUIA", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+18186897323", "ApiVersion"=>"2010-04-01"}

      end

      it "matches a user with a school when they've texted in correctly, ignoring case" do 
        post '/sms', @school_params

        user = User.where(phone: '8186897323').first

        expect(user.school_id).to eq @school.id
      end

      it "updates a user's language to Spanish when they text the spanish code" do
        post '/sms', @school_params_espanish
        user = User.where(phone: '8186897323').first

        expect(user.locale).to eq 'es'
      end

    end


    it "enqueues a texting job" do
      Sidekiq::Testing::fake! do
        expect {
          post '/sms', @sms_params

          # to change some other job, whatever it is....
        }.to change(StartDayWorker.jobs, :size).by(1)
      end
    end

    it "does not message a pre-existing user with their first story" do
      user = User.create(phone: "8186897323")

      Sidekiq::Testing::fake! do
        expect {
          post '/sms', @sms_params
        }.to change(StartDayWorker.jobs, :size).by(0)
      end

    end

    it "does not add a new user when they already exist" do
      user = User.create(phone: "8186897323")

      Sidekiq::Testing::fake! do
        expect {
          post '/sms', @sms_params
        }.to change{User.count}.by(0)
      end
    end
  end

  # test that skips someone without an ID
  # test the new user does indeed add a field to enrollment queue
  context 'post /' do
    before(:example) do
      post '/', @enroll_params
    end

    it "processes phone numbers???" do
    end

    it "adds David, Phil, and Aubrey to the DB" do
      expect(User.where(phone: @enroll_params[:phone_0], child_name: @enroll_params[:name_0]).first).to_not be_nil
      expect(User.where(phone: @enroll_params[:phone_1], child_name: @enroll_params[:name_1]).first).to_not be_nil
      expect(User.where(phone: @enroll_params[:phone_2], child_name: @enroll_params[:name_2]).first).to_not be_nil
    end

    it "correctly assigns teacher" do
      users = User.where(phone: [@enroll_params[:phone_0], @enroll_params[:phone_1], @enroll_params[:phone_3]])
      teacher = Teacher.where(email: @enroll_params[:teacher_email]).first
      for user in users
        expect(user.teacher.id).to eq teacher.id
      end
    end

    it "only adds one teacher" do 
      expect(Teacher.count).to eq 1
    end

    it "updates teacher row when it's the same teacher (same email)" do
      post '/', { teacher_email: @enroll_params[:teacher_email], name_0: "Ben McPeek", phone_0: "8183210034", teacher_signature: "McEsterWahl" }
      # previous teacher was updated...
      expect(Teacher.count).to eq 1
      # user was inserted...
      expect(User.where(child_name: "Ben McPeek").first).to_not be_nil
      # same teacher
      expect(User.where(child_name: "Ben McPeek").first.teacher).to eq Teacher.where(email: @enroll_params[:teacher_email]).first
      # there are 4 users now...
      expect(User.count).to eq 4
    end

  end

  # webmock stub template
  context "enrolling users" do

    it "says hello" do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq("Bring me to the Kingdom of Angels")
    end

    it "does enroll" do 
      require 'httparty'
      # post '/enroll', { time_interval: 600 }
    end
  end


end