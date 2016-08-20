require 'spec_helper'
require 'rack/test'
require 'timecop'
require 'active_support/time'
require 'app'


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

      @sw = ScheduleWorker.new

      @sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"Please, you have to help me, I've been trapped in the Phantom Zone for centuries, there's not much tiiiiiiiiiiiiiiiiiiiiiiiiii.......", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+18186897323", "ApiVersion"=>"2010-04-01"}
      @enroll_params = { :name_1 => "Phil Esterman", :phone_1 => "5612125831",
                         :teacher_signature => "McEsterWahl", :teacher_email => "david.mcpeek@yale.edu"
      }

    end

    before(:each) { allow(Pony).to(receive(:mail).with(hash_including(:to, :cc, :from, :headers, :body, :subject))) }

    before(:each) do
      stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=Hi%2C%20this%20is%20StoryTime.%20We%27ll%20be%20texting%20you%20free%20books%21%0A%0A&script=day1&next_sequence=firstmessage2",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=5612125831&text=Hi%2C%20this%20is%20McEsterWahl.%20I%27ll%20be%20texting%20Phil%20books%20with%20StoryTime%21%0A%0A&script=day1&next_sequence=firstmessage2",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

    end

    before(:each) do
      Sidekiq::Testing::inline! do
        post '/sms', @sms_params
        post '/', @enroll_params
      end

      @u1 = User.where(phone: '8186897323').first
      @u2 = User.where(phone: '5612125831').first


      Sidekiq::Worker.clear_all
      # @time_range = 10.minutes
    end

    after(:each) { Timecop.return }

    it 'added the users to the db correctly' do
      expect(@u1).to_not be_nil
      expect(@u2).to_not be_nil
    end

    it 'sends day1 to new user' do
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"Please, you have to help me, I've been trapped in the Phantom Zone for centuries, there's not much tiiiiiiiiiiiiiiiiiiiiiiiiii.......", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+15555555555", "ApiVersion"=>"2010-04-01"}

      expect(@day1).to receive(:run_sequence).with('5555555555', :init)
      Sidekiq::Testing.inline! do
        post '/sms', sms_params
      end

    end 

    it 'does the first night of the program correctly for @u1 (on story 2) and @u2 (on story 1)' do
      Timecop.freeze(Time.new(2016, 6, 27, 23, 0, 0, 0)) # Monday
      allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [1,3,5], &block)
      end

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "running sequence with args #{args}"
      end

      # allow_any_instance_of(StartDayWorker).to receive(:perform).and_wrap_original do |original_method, *args| 
      #   puts "ASSSSSSSS!!!!!!!"
      # end 

      # users' initial state...
      expect(User.where(phone: '5612125831').first.state_table.story_number).to eq 0
      expect(User.where(phone: '8186897323').first.state_table.story_number).to eq 1

      expect(User.count).to eq 2
      # expect(StartDayWorker).to receive(:perform_async).exactly(User.count).times

      expect(@day1).to receive(:run_sequence).once.with('5612125831', :init)
      expect(@day2).to receive(:run_sequence).once.with('8186897323', :init)

      Sidekiq::Testing.inline! do
        @sw.perform
      end

      expect(User.where(phone: '5612125831').first.state_table.story_number).to eq 1
      expect(User.where(phone: '8186897323').first.state_table.story_number).to eq 2



      # Tuesday, we're not sending any over!
      Timecop.freeze(Time.now + 1.days)

      expect_any_instance_of(Birdv::DSL::StoryTimeScript).not_to receive(:run_sequence)

      Sidekiq::Testing.inline! do
        @sw.perform
      end

      # Wednesday, it's StoryTime day!
      Timecop.freeze(Time.now + 1.days)


      expect {
        Sidekiq::Testing.fake! do
          @sw.perform
        end
        ScheduleWorker.drain
      }.to change{StartDayWorker.jobs.size}.by 2


    end

    it 'moves up a day for both users' do

      Timecop.freeze(Time.new(2016, 6, 29, 23, 0, 0, 0)) # Wednesday
      allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [1,3,5], &block)
      end

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "running sequence with args #{args}"
      end

      User.where(phone: '5612125831').first.state_table.update(story_number: 1)
      User.where(phone: '8186897323').first.state_table.update(story_number: 2)


      expect(@day2).to receive(:run_sequence).once.with('5612125831', :init)
      expect(@day3).to receive(:run_sequence).once.with('8186897323', :init)


      Sidekiq::Testing.inline! do
        @sw.perform
      end

      expect(User.where(phone: '5612125831').first.state_table.story_number).to eq 2
      expect(User.where(phone: '8186897323').first.state_table.story_number).to eq 3

    end

  end

end