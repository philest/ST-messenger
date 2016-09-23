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

  context 'delay test', delay: true do
    before(:all) do
      # load scripts
      Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_sms_scripts/*")
         .each {|f| require_relative f }

      @day1 = Birdv::DSL::ScriptClient.scripts['sms']["day1"]
      @day2 = Birdv::DSL::ScriptClient.scripts['sms']["day2"]
      @day3 = Birdv::DSL::ScriptClient.scripts['sms']["day3"]

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

      @sw = ScheduleWorker.new

      @sms_params = {"ToCountry"=>"US", "ToState"=>"CT", "SmsMessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "NumMedia"=>"0", "ToCity"=>"DARIEN", "FromZip"=>"90066", "SmsSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "FromState"=>"CA", "SmsStatus"=>"received", "FromCity"=>"LOS ANGELES", "Body"=>"Please, you have to help me, I've been trapped in the Phantom Zone for centuries, there's not much tiiiiiiiiiiiiiiiiiiiiiiiiii.......", "FromCountry"=>"US", "To"=>"+12032023505", "ToZip"=>"06820", "NumSegments"=>"1", "MessageSid"=>"SM3461cd2ebfa515456d2a956c03dee788", "AccountSid"=>"ACea17e0bba30660770f62b1e28e126944", "From"=>"+18186897323", "ApiVersion"=>"2010-04-01"}
      @enroll_params = { :name_1 => "Phil Esterman", :phone_1 => "5612125831",
                         :teacher_signature => "McEsterWahl", :teacher_email => "david.mcpeek@yale.edu"
      }

    end

    before(:each) { allow(Pony).to(receive(:mail).with(hash_including(:to, :cc, :from, :headers, :body, :subject))) }

    before(:each) do

      stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=Hi%2C%20this%20is%20StoryTime.%20We%27ll%20be%20texting%20you%20free%20books%21%0A%0A&script=day1&next_sequence=smsCallToAction&last_sequence=firstmessage",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})


         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=Great%21%20We%27ll%20start%20sending%20you%20stories%20%3A%29&sender=%2B12032023505",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=8186897323%20texted%20StoryTime%3A%0AMsg%3A%20%22TEXT%22&sender=%2B12032750946",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B15612125831&text=8186897323%20texted%20StoryTime%3A%0AMsg%3A%20%22TEXT%22&sender=%2B12032750946",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

          stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=8186897323%20texted%20StoryTime%3A%0Awe%20responded%20with%20%22Great%21%20We%27ll%20start%20sending%20you%20stories%20%3A%29%22&sender=%2B12032750946",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
        with(:body => "recipient=8186897323&text=Hi%2C%20this%20is%20StoryTime.%20We%27ll%20be%20texting%20you%20free%20books%21%0A%0A&script=day1&next_sequence=smsCallToAction&last_sequence=firstmessage").
        to_return(:status => 200, :body => "", :headers => {})

        stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=Great%21%20We%27ll%20start%20sending%20you%20stories%20%3A%29&sender=%2B12032023505").
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=A%20new%20user%208186897323%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
        with(:body => "recipient=%2B15612125831&text=A%20new%20user%208186897323%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946",
             :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})


        stub_request(:post, "http://localhost:4567/txt").
        with(:body => "recipient=%2B15612125831&text=8186897323%20texted%20StoryTime%3A%0Awe%20responded%20with%20%22Great%21%20We%27ll%20start%20sending%20you%20stories%20%3A%29%22&sender=%2B12032750946",
             :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})

        stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=A%20new%20user%205555555555%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

          stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B15612125831&text=A%20new%20user%205555555555%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=A%20new%20user%208186897323%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B15612125831&text=A%20new%20user%208186897323%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=A%20new%20user%205555555555%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B15612125831&text=A%20new%20user%205555555555%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=8186897323%20texted%20StoryTime%3A%0AMsg%3A%20%22TEXT%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})


         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B15612125831&text=8186897323%20texted%20StoryTime%3A%0AMsg%3A%20%22TEXT%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})
     

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=8186897323%20texted%20StoryTime%3A%0Awe%20responded%20with%20%22Great%21%20We%27ll%20start%20sending%20you%20stories%20%3A%29%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B15612125831&text=8186897323%20texted%20StoryTime%3A%0Awe%20responded%20with%20%22Great%21%20We%27ll%20start%20sending%20you%20stories%20%3A%29%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B15612125831&text=A%20new%20user%208186897323%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})
     

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B15612125831&text=A%20new%20user%208186897323%20has%20enrolled%20by%20texting%20in%3A%0ACode%3A%20%22Please%2C%20you%20have%20to%20help%20me%2C%20I%27ve%20been%20trapped%20in%20the%20Phantom%20Zone%20for%20centuries%2C%20there%27s%20not%20much%20tiiiiiiiiiiiiiiiiiiiiiiiiii.......%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})


         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=8186897323%20texted%20StoryTime%3A%0Awe%20responded%20with%20%22Hi%2C%20this%20is%20StoryTime%21%20We%20help%20your%20teacher%20send%20free%20nightly...%22&sender=%2B12032750946").
         to_return(:status => 200, :body => "", :headers => {})

         stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=%2B18186897323&text=8186897323%20texted%20StoryTime%3A%0Awe%20responded%20with%20%22Hi%2C%20this%20is%20StoryTime%21%20We%20help%20your%20teacher%20send%20free%20nightly...%22&sender=%2B12032750946").
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