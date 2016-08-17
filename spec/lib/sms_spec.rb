require 'spec_helper'
require 'bot/dsl'
load 'workers.rb'

# testing is useful to simulate behavior and uncover blatant bugs.
# overtesting is just wasteful.

describe 'sms' do

  context 'when sending sms/mms to st-enroll' do

    # TODO: have to figure out a way to get the correct responses from st-enroll back to birdv.
    # 
    # The thing is, we're calling a worker in st-enroll/txt, meaning that we can't immediately get
    # the Twilio results. We somehow have to tie st-enroll and birdv together, perhaps through some job id or something.
    # Or maybe just the person's phone number or something, which is POSTED back through the callback url 
    # on the st-enroll side (the Twilio callback url, that is).


    it 'checks to see if the POST request failed and does something about it'

    it 'sends a POST request to the correct URLs in st-enroll'

  end


  # context 'running sequences' do
  #   it 'uses phone number instead of fb_id to search for users' do
  #     script = Birdv::DSL::ScriptClient.new_script 'day2', 'sms' do
  #       sequence 'test' do; end
  #     end
  #     # make sure that running the sequence update's the user's last_sequence_seen
  #     user = User.create(phone: '8186897323', platform: 'sms')

  #     script.run_sequence(user.phone, 'test')

  #     u = User.where(phone: '8186897323').first

  #     expect(u.state_table.last_sequence_seen).to eq 'test'

  #   end

  #   it 'selects from the pool of sms scripts when the script type is sms' do
  #   end

  # end

  context 'day1 mms' do
    before(:each) do
      # have to reload the damn script....
      load 'sms_sequence_scripts/01.rb'
      @day1 = Birdv::DSL::ScriptClient.scripts['sms']['day1']

      puts "scripts = #{Birdv::DSL::ScriptClient.scripts}"

      stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=Hi%2C%20this%20is%20Mx.%20GlottleStop.%20I%27ll%20be%20texting%20your%20child%20books%20with%20StoryTime%21%0A%0A&script=day1&next_sequence=firstmessage2",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

           stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=Hi%2C%20this%20is%20My%20Asshole.%20We%27ll%20be%20texting%20you%20free%20books%20with%20StoryTime%21%0A%0A&script=day1&next_sequence=firstmessage2",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})


      stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=You%20can%20start%20early%20if%20you%20have%20Facebook%20Messenger.%20Tap%20here%20and%20enter%20%27go%27%3A%0Ajoinstorytime.com%2Fgo&script=day1&next_sequence=image1",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})


       stub_request(:post, "http://localhost:4567/txt").
         with(:body => "recipient=8186897323&text=Hi%2C%20this%20is%20StoryTime.%20We%27ll%20be%20texting%20you%20free%20books%21%0A%0A&script=day1&next_sequence=firstmessage2",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})
    end

    context 'the user has a teacher' do

      before(:each) do
        @teacher = Teacher.create(signature: 'Mx. GlottleStop')
        @user = User.create(phone: '8186897323')
        @teacher.add_user(@user)
      end
      
      it 'sends the has_teacher.first text to the user' do
        expect(@day1).to receive(:send_sms_helper).with(@user.phone, "enrollment.body_sprint.has_teacher.first", 'day1', 'firstmessage2')
        
        @day1.run_sequence(@user.phone, 'firstmessage')
      end

      it 'sends the has_teacher.second text to the user' do
        expect(@day1).to receive(:send_sms_helper).with(@user.phone, "enrollment.body_sprint.has_teacher.second", 'day1', 'image1')

        @day1.run_sequence(@user.phone, 'firstmessage2')
      end

    end 


    context 'the user has a school' do

      before(:each) do
        @school = School.create(signature: 'My Asshole')
        @user = User.create(phone: '8186897323')
        @school.add_user(@user)
      end
      
      it 'sends the has_school.first text to the user' do
        expect(@day1).to receive(:send_sms_helper).with(@user.phone, "enrollment.body_sprint.has_school.first", 'day1', 'firstmessage2')
        
        @day1.run_sequence(@user.phone, 'firstmessage')
      end

      it 'sends the has_school.second text to the user' do
        expect(@day1).to receive(:send_sms_helper).with(@user.phone, "enrollment.body_sprint.has_school.second", 'day1', 'image1')

        @day1.run_sequence(@user.phone, 'firstmessage2')
      end

    end 

    context 'default' do

      before(:each) do
        @user = User.create(phone: '8186897323')
      end
      
      it 'sends the default text to the user' do
        expect(@day1).to receive(:send_sms_helper).with(@user.phone, "enrollment.body_sprint.has_none.first", 'day1', 'firstmessage2')
        
        @day1.run_sequence(@user.phone, 'firstmessage')
      end

      it 'sends the has_none.second text to the user' do
        expect(@day1).to receive(:send_sms_helper).with(@user.phone, "enrollment.body_sprint.has_none.second", 'day1', 'image1')

        @day1.run_sequence(@user.phone, 'firstmessage2')
      end

    end 

  end

  context 'StoryTimeScript#translate_sms', mms:true do
    context 'name codes' do
      it 'translates shit' do
        @s = Birdv::DSL::StoryTimeScript.new 'day1', 'sms' do; end

        user = User.create phone: '8186897323'
        @s.name_codes "hi there", '8186897323'


      end
      it 'finds a user if they have a facebook id but no phone'

      it 'finds a user if they have a phone but no facebook id'

      it 'returns the correct string'
    end
    it 'translates text correctly'
  end





end






