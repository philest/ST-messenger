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
    TextApi 
  end

  context 'delay test', delay: true do
    before(:all) do
      # load scripts
      Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_sms_scripts/*")
         .each {|f| require_relative f }

      @day1 = Birdv::DSL::ScriptClient.scripts['sms']["day1"]
      @day2 = Birdv::DSL::ScriptClient.scripts['sms']["day2"]
      @day3 = Birdv::DSL::ScriptClient.scripts['sms']["day3"]
      @remind = Birdv::DSL::ScriptClient.scripts['sms']['remind']

      @sw = ScheduleWorker.new

    end

    before(:each) { allow(Pony).to(receive(:mail).with(hash_including(:to, :cc, :from, :headers, :body, :subject))) }

    before(:each) do
      

    end

    before(:each) do
      20.times do |i|
        User.create(phone: "#{i}", platform: "sms")
      end

      Sidekiq::Worker.clear_all

    end

    after(:each) { Timecop.return }

    it 'does the first night correctly for all 30 guys' do

      Timecop.freeze(Time.new(2016, 6, 27, 23, 0, 0, 0)) # Monday
      allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [1,3,5], &block)
      end

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "running sequence with args #{args}"
      end

      Sidekiq::Testing.inline! do
        @sw.perform
      end

    end
    
  end


  # DIFFERENT THING NOW
  context 'multi-day test' do
    before(:all) do
      # load scripts
      Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_sms_scripts/*")
         .each {|f| require_relative f }

      @day1 = Birdv::DSL::ScriptClient.scripts['sms']["day1"]
      @day2 = Birdv::DSL::ScriptClient.scripts['sms']["day2"]
      @day3 = Birdv::DSL::ScriptClient.scripts['sms']["day3"]
      @remind = Birdv::DSL::ScriptClient.scripts['sms']["remind"]

      @sw = ScheduleWorker.new

      @sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"Please, you have to help me, I've been trapped in the Phantom Zone for centuries, there's not much tiiiiiiiiiiiiiiiiiiiiiiiiii.......", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+18186897323", "ApiVersion"=>"2010-04-01"}
      @enroll_params = { :name_1 => "Phil Esterman", :phone_1 => "5612125831",
                         :teacher_signature => "McEsterWahl", :teacher_email => "david.mcpeek@yale.edu"
      }



    end

    before(:each) { allow(Pony).to(receive(:mail).with(hash_including(:to, :cc, :from, :headers, :body, :subject))) }

    before(:each) do

      allow_any_instance_of(TextApi).to  receive(:sms).and_wrap_original do |original_method, *args|
        puts "stubbing SMS with #{args}"
      end

      allow_any_instance_of(TextingWorker).to receive(:perform).and_wrap_original do |original_method, *args|
        puts "stubbing TimerWorker with #{args}"
      end

      allow_any_instance_of(MessageWorker).to receive(:perform).and_wrap_original do |original_method, *args|
        puts "stubbing TimerWorker with #{args}"
      end

      allow_any_instance_of(TextApi).to  receive(:mms).and_wrap_original do |original_method, *args|
        puts "stubbing MMS with #{args}"
      end

      allow_any_instance_of(TextApi).to  receive(:mms).and_wrap_original do |original_method, *args|
        puts "stubbing MMS with #{args}"
      end

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args|
        puts "running sequence with #{args}"
      end

      allow(@day1).to receive(:send_sms).and_wrap_original do |original_method, *args|
        puts "stubbing send_sms() with #{args}"
      end
      allow(@day1).to receive(:send_mms).and_wrap_original do |original_method, *args|
        puts "stubbing send_mms() with #{args}"
      end
      allow(@day2).to receive(:send_sms).and_wrap_original do |original_method, *args|
        puts "stubbing send_sms() with #{args}"
      end
      allow(@day2).to receive(:send_mms).and_wrap_original do |original_method, *args|
        puts "stubbing send_mms() with #{args}"
      end
      allow(@day3).to receive(:send_sms).and_wrap_original do |original_method, *args|
        puts "stubbing send_sms() with #{args}"
      end
      allow(@day3).to receive(:send_mms).and_wrap_original do |original_method, *args|
        puts "stubbing send_mms() with #{args}"
      end


    end

    before(:each) do
      Timecop.freeze(Time.new(2016, 6, 26, 23, 0, 0, 0))

      Sidekiq::Testing::inline! do
        post '/sms', @sms_params
        post '/', @enroll_params
      end

      @u1 = User.where(phone: '8186897323').first
      @u2 = User.where(phone: '5612125831').first


      Sidekiq::Worker.clear_all
      # @time_range = 10.minutes
    end

    before(:each) do
      @school = School.create(name: "TurkeyFuck Academy", signature: "the TurkeyFuck Academy", code: "turkey|fuck")
      @teacher = Teacher.create(name: "Ms. TurkeyFuck", signature: "Ms. TurkeyFuck", code: "turkeyteacher|teacherfuck")
      @school.add_teacher(@teacher)

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

    it 'adds user to a school' do
      text_body = "turkey"
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>text_body, "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+15555555555", "ApiVersion"=>"2010-04-01"}

      Sidekiq::Testing.inline! do
        post '/sms', sms_params
      end

      user = User.where(phone: "5555555555").first
      expect(user.school.name).to eq "TurkeyFuck Academy"
      expect(user.teacher).to be_nil
      

    end

    it "handles weird regexes", regex: true do
      text_body = "ywca"
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>text_body, "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+15555555555", "ApiVersion"=>"2010-04-01"}
      School.create(name: "YWCA", signature: "the YWCA", code: "ywca|yw")

      Sidekiq::Testing.inline! do
        post '/sms', sms_params
      end

      user = User.where(phone: "5555555555").first
      expect(user.school.name).to eq "YWCA"
      expect(user.locale).to eq 'en'
      

    end

    it "handles weird regexes II", regex: true do
      text_body = "ywca"
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>text_body, "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+15555555555", "ApiVersion"=>"2010-04-01"}
      School.create(name: "YWCA", signature: "the YWCA", code: "yw|ywca")

      Sidekiq::Testing.inline! do
        post '/sms', sms_params
      end

      user = User.where(phone: "5555555555").first
      expect(user.school.name).to eq "YWCA"
      expect(user.locale).to eq 'es'
      

    end

    it "handles weird regexes III", regex: true do
      text_body = "teache r"
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>text_body, "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+15555555555", "ApiVersion"=>"2010-04-01"}
      Teacher.create(name: "TeacherMan", signature: "the TeacherMan", code: "teacher|teach")

      Sidekiq::Testing.inline! do
        post '/sms', sms_params
      end

      user = User.where(phone: "5555555555").first
      expect(user.teacher.name).to eq "TeacherMan"
      expect(user.locale).to eq 'en'
      
    end

    it "handles weird regexes IV", regex: true do
      text_body = "TEACHER  "
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>text_body, "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+15555555555", "ApiVersion"=>"2010-04-01"}
      Teacher.create(name: "TeacherMan", signature: "the TeacherMan", code: "teach|teacher")

      Sidekiq::Testing.inline! do
        post '/sms', sms_params
      end

      user = User.where(phone: "5555555555").first
      expect(user.teacher.name).to eq "TeacherMan"
      expect(user.locale).to eq 'es'
      

    end


    it "adds user to a teacher's classroom" do
      text_body = "turkeyteacher"
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>text_body, "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+15555555555", "ApiVersion"=>"2010-04-01"}

      Sidekiq::Testing.inline! do
        post '/sms', sms_params
      end

      user = User.where(phone: "5555555555").first
      expect(user.school.name).to eq "TurkeyFuck Academy"
      expect(user.teacher.name).to eq "Ms. TurkeyFuck"

    end

    it 'adds a user to the db, but unsubscribed' do

      expect(@u1.state_table.subscribed?).to eq false
      expect(@u2.state_table.subscribed?).to eq false

    end

    it 'sends the initial sms to these users, but not the second one' do
      Timecop.freeze(Time.new(2016, 6, 27, 23, 0, 0, 0)) # Monday
      allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, (0..7).to_a, &block)
      end
      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "running sequence with args #{args}"
      end

      Sidekiq::Testing.inline! do
        expect(@day1).to receive(:run_sequence).once.with('5612125831', :init)
        @sw.perform
      end

      Timecop.freeze(Time.now + 3.days)

      expect(@sw.within_time_range(@u2, 5.minutes)).to be true

      Sidekiq::Testing.inline! do
        expect(StartDayWorker).to receive(:perform_in).twice
        expect_any_instance_of(Birdv::DSL::StoryTimeScript).not_to receive(:run_sequence)
        @sw.perform
      end
    end

    it 're-subscribes folks after they text \'sms\'' do
      sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"TEXT", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+18186897323", "ApiVersion"=>"2010-04-01"}
      Timecop.freeze(Time.new(2016, 6, 29, 23, 0, 0, 0)) # Monday
      allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, (0..7).to_a, &block)
      end
      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "running sequence with args #{args}"
      end

      @u1.reload()
      expect(@u1.state_table.subscribed?).to be false

      expect {
        post '/sms', sms_params
        @u1.reload()
      }.to change{@u1.state_table.subscribed?}.to true

    end


    it 'sends a reminder text to peeps who have not texted in anything' do
      # @u1 is david, he's our guy
      expect(@u1.enrolled_on).to eq Time.new(2016, 6, 26, 23, 0, 0, 0)
      Timecop.freeze(Time.new(2016, 6, 29, 23, 0, 0, 0))

      allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, (0..7).to_a, &block)
      end

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "running sequence with args #{args}"
      end

      expect(@remind).to receive(:run_sequence).with('8186897323', :remind)

      Sidekiq::Testing.inline! do
        @sw.perform
      end

    end

    it "automatically enrolls peeps into SMS if they haven't responded after 8 days" do
      Timecop.freeze(Time.new(2016, 7, 4, 23, 0, 0, 0))

      @u1.reload
      expect(@u1.state_table.subscribed?).to be false

      allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, (0..7).to_a, &block)
      end

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "running sequence with args #{args}"
      end

      expect(@day2).to receive(:run_sequence).with('8186897323', :init)

      Sidekiq::Testing.inline! do
        @sw.perform
      end

      @u1.reload
      expect(@u1.state_table.subscribed?).to be true
      expect(@u1.state_table.story_number).to eq 2
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

      User.where(phone: '8186897323').first.state_table.update(subscribed?: true)

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

      User.where(phone: '5612125831').first.state_table.update(story_number: 1, subscribed?: true)
      User.where(phone: '8186897323').first.state_table.update(story_number: 2, subscribed?: true)


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