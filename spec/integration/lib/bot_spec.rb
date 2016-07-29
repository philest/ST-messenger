require 'spec_helper'
require 'rack/test'
require 'timecop'
require 'active_support/time'

require 'bot'
require 'facebook/messenger'


module RSpecMixin
  include Rack::Test::Methods
  def app() Facebook::Messenger::Server end
end

# do the stuff here: http://recipes.sinatrarb.com/p/testing/rspec
describe 'TheBot' do

  # => A crapton of configuration follows!
  #
  #
  #
  include Facebook::Messenger

  let(:verify_token) { ENV['FB_VERIFY_TKN'] }
  let(:challenge) { ENV['FB_ACCESS_TKN'] }    # is this correct?

  before do
    Facebook::Messenger.configure do |config|
      # config.access_token = ENV['FB_ACCESS_TKN']
      # config.app_secret   = ENV['APP_SECRET']
      config.verify_token = verify_token
    end
  end

  include RSpecMixin

  before(:all) do
    @time = Time.new(2016, 6, 16, 23, 0, 0, 0) # with 0 utc-offset
    @time_range = 10.minutes.to_i
    @interval = @time_range / 2.0               
    
    Timecop.freeze(@time)

    @sw =  ScheduleWorker.new

    Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_scripts/*")
      .each {|f| require_relative f }

    @params = { 
      :name_0 => "Phil Esterman", :phone_0 => "5612125831",
      :name_1 => "David McPeek", :phone_1 => "8186897323",
      :name_2 => "Aubrey Wahl", :phone_2 => "3013328953",
      :teacher_signature => "McEsterWahl", :teacher_email => "david.mcpeek@yale.edu",
    }   

    @aubrey   = '10209571935726081' # aubrey 

    @make_aubrey  = lambda do
      User.create phone:'3013328953', first_name:'Aubs', last_name:'Wahl', fb_id:@aubrey, child_name:'Lil Aubs'
    end
  end

  after(:all) do
    Timecop.return
    Birdv::DSL::ScriptClient.clear_scripts # TODO, make this happen in spec helper
  end

  after(:each) do
    Sidekiq::Worker.clear_all
  end
  
  before(:example) do
    #WebMock.allow_net_connect!
  end

  after(:example) do
    WebMock.disable_net_connect!
  end

  before(:each) do
    @aubrey_db = User.create()
  end
  



  # => We do the POST tests
  #
  #
  #
  describe 'POST' do
    context 'with the right verify token' do
      it 'responds with the challenge' do
        get '/', 'hub.verify_token' => verify_token,
                 'hub.challenge' => challenge

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(challenge)
      end
    end


    context 'message' do 

      it 'starts a day yob when user requests it' do
        @aub_db = @make_aubrey.call

        3.times {expect(User).to receive(:where).and_return([@aub_db])}
       
        body = JSON.generate(
              object: 'page',
              entry: [
                {
                  id: '1',
                  time: 145_776_419_824_6,
                  messaging: [
                    {
                      sender: {
                        id: @aubrey
                      },
                      recipient: {
                        id: '3'
                      },
                      timestamp: 145_776_419_762_7,
                      message: {
                        mid: 'mid.1457764197618:41d102a3e1ae206a38',
                        seq: 5,
                        text: 'day2'
                      }
                    }
                  ]
                }
              ]
            )

          signature = OpenSSL::HMAC.hexdigest(
            OpenSSL::Digest.new('sha1'),
            Facebook::Messenger.config.app_secret,
            body
          )
        
          # this is the actual test
          Sidekiq::Testing.fake! do
            expect {
              post '/', body, 'HTTP_X_HUB_SIGNATURE' => "sha1=#{signature}"
              post '/', body, 'HTTP_X_HUB_SIGNATURE' => "sha1=#{signature}"
              post '/', body, 'HTTP_X_HUB_SIGNATURE' => "sha1=#{signature}"
            }.to change(BotWorker.jobs, :size).by(3)
          end
      end


      context 'postback' do
        before(:all) do

        end

      end
      # TODO: many tests  
    end

    # TODO: oh jeez where are the tests!!!!!????
  end

  describe 'multiple days worth of user interactions', integration:true do
    before(:all) do
      # clean everything up
      # DatabaseCleaner.clean
      



      Sidekiq::Worker.clear_all
      
      @test_curriculum = 666
      
      # load curricula
      Birdv::DSL::Curricula.load "#{File.expand_path(File.dirname(__FILE__))}/test_curric/", true
      
      # load scripts
      Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_scripts/*")
         .each {|f| require_relative f }

      @s900 = Birdv::DSL::ScriptClient.scripts["day900"]
      @s901 = Birdv::DSL::ScriptClient.scripts["day901"]
      @s902 = Birdv::DSL::ScriptClient.scripts["day902"]
      @s903 = Birdv::DSL::ScriptClient.scripts["day903"]
      @s904 = Birdv::DSL::ScriptClient.scripts["day904"]


      @make_story_btn_press = lambda { |sender_id, script, btn_name|
      return JSON.generate(
            object: 'page',
            entry: [
              {
                id: '1',
                time: 145_776_419_824_6,
                messaging: [
                  {
                    sender: {
                      id: sender_id
                    },
                    recipient: {
                      id: '1337'
                    },
                    timestamp: 145_776_419_762_7,
                    'postback' => {
                      'payload' => script.script_payload(btn_name)
      }}]}])}

      @make_signature = lambda { |body|
        return 'HTTP_X_HUB_SIGNATURE' => "sha1=#{
          OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new('sha1'),
          Facebook::Messenger.config.app_secret,
          body)}"
      }
  end

    before(:each) do
      
      @num_users = 0

      @get_id = lambda do return (@num_users += 1).to_s end


      @num_ontime = 7
      @num_late = 2
      @on_time_users = []
      @late_users = []

      @start_time = @time

      Timecop.freeze(@start_time - 12.days)


      # On-time!!!!  (should be 7 users)
      #
      # 
      5.times {
        @on_time_users  << User.create(fb_id: @get_id.call, 
                                       send_time: @start_time, first_name: 'David', last_name: 'McPeek',
                                       curriculum_version: @test_curriculum)
      }

      # 6:55:00pm, just early enough
      @on_time_users << User.create(fb_id: @get_id.call, 
                                    send_time: @start_time - @interval, first_name: 'David', last_name: 'McPeek',
                                    curriculum_version: @test_curriculum)
      # 7:04:59pm, almost late
      @on_time_users << User.create(fb_id: @get_id.call, first_name: 'David', last_name: 'McPeek',
                                    send_time: @start_time + (@interval-1.minute) + 59.seconds, 
                                    curriculum_version: @test_curriculum)

      # Late!!!! (should be 2 users)
      #
      #
      # 6:54:59
      @late_users << User.create(fb_id: @get_id.call, first_name: 'David', last_name: 'McPeek',
                                 send_time: @start_time - (@interval+1.minute) + 59.seconds, 
                                 curriculum_version: @test_curriculum)
      # 7:05
      @late_users << User.create(fb_id: @get_id.call, first_name: 'David', last_name: 'McPeek',
                                 send_time: @start_time + @interval, 
                                 curriculum_version: @test_curriculum)

      @num_users.times do |x|
        User.where(fb_id:(x+1).to_s).first.update(curriculum_version: @test_curriculum)
        puts "User fb id: #{User.where(fb_id:(x+1).to_s).first.fb_id}, num users : #{@num_users}"
      end

      Timecop.freeze(@start_time)
    end

    context 'when everyone is on day 901' do
      before(:all) do
        @starting_day =  901
        @num_users = @num_users
      end

      before(:each) do
        @num_users.times do |x|
          u = User.where(fb_id:(x+1).to_s).first.state_table.update(story_number: @starting_day)
        end
      end

      it 'sends out previous days story again because no one read' do
        # test if perform_async is called the right number of times.
        # i know this isn't really as good as checking the queue, but it'll
        # have to do for now

        
        allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
          original_method.call(*args, [1,3,5], &block)
        end

        expect(StartDayWorker).to receive(:perform_async).exactly(@num_ontime).times
        expect_any_instance_of(Birdv::DSL::StoryTimeScript).not_to receive(:run_sequence)

        Sidekiq::Testing.inline! do
          @sw.perform (@time_range/2)
        end
      end

      it 'sends next days stories to folks who have read previous days story', simple:true do
        
        puts "TODAY IS #{Time.now.wday}"
        # 4 ppl read yesterda (story 900)
        Timecop.freeze(@start_time-1.day)
        4.times do |i|
          User.where(fb_id:(i+1).to_s).first.state_table.update(last_story_read?: true, last_story_read_time: Time.now)
        end


        
        # allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        #   original_method.call(*args, [1,3,5], &block)
        # end

        # 1 person who is not scheduled but also read yesterday
        User.all.last.state_table.update(last_story_read?: true)

        Timecop.freeze(@start_time)
        
        expect(@s900).not_to receive(:run_sequence)       
        expect(@s901).to     receive(:run_sequence).exactly(3).times
        expect(@s902).to     receive(:run_sequence).exactly(4).times
        expect(@s903).not_to receive(:run_sequence)
        expect(@s904).not_to receive(:run_sequence)

        # run the the clock
        expect{
          Sidekiq::Testing.inline! do
            @sw.perform (@time_range/2)
          end
        }.to change{User.where(fb_id:@on_time_users[0].fb_id)
                        .first.state_table
                        .story_number}.by 1
      end

      it 'sends out correct stories (this is a big ol\' multi-day test', og:true do
        # 4 ppl read yesterday (story 900)
        4.times do |i| 
          User.where(fb_id:(i+1).to_s).first.state_table.update(last_story_read?: true)
        end       

        
        # allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        #   puts "OG ARGS #{args}"
        #   original_method.call(*args, &block)
        # end

        expect(@s900).not_to receive(:run_sequence)       
        expect(@s901).to     receive(:run_sequence).with(anything(), :init).exactly(3).times
        expect(@s902).to     receive(:run_sequence).with(anything(), :init).exactly(4).times
        expect(@s903).not_to receive(:run_sequence)
        expect(@s904).not_to receive(:run_sequence)

        puts Time.now.wday

        # run the the clock
        expect{
          Sidekiq::Testing.inline! do
            @sw.perform (@time_range/2)
          end
        }.not_to change{User.where(fb_id:@late_users[0].fb_id)
                        .first.state_table
                        .story_number}

        # So at this point, users 5-7 have gotten :init from s901
        # and users 1-4 have gotten :init from s902. What we're 
        # gonna do now is have user's {[2,4]U[6]} press the 
        # story buttons from their respective days.
        b1 = @make_story_btn_press.call('2', @s902, :scratchstory)
        b2 = @make_story_btn_press.call('3', @s902, :scratchstory)
        b3 = @make_story_btn_press.call('4', @s902, :scratchstory)
        b4 = @make_story_btn_press.call('6', @s901, :cookstory)




        allow(@s902).to receive(:run_sequence).with('2', :scratchstory).and_call_original
        allow(@s902).to receive(:run_sequence).with('3', :scratchstory).and_call_original
        allow(@s902).to receive(:run_sequence).with('4', :scratchstory).and_call_original
        allow(@s902).to receive(:send_story).exactly(3).times

        expect{
          Sidekiq::Testing.inline! do 
            post '/', b1, @make_signature.call(b1)
          end
        }.to change{User.where(fb_id:'2').first.state_table.last_story_read?}
        
        expect{
          Sidekiq::Testing.inline! do 
            post '/', b2, @make_signature.call(b2)
          end
        }.to change{User.where(fb_id:'3').first.state_table.last_story_read?}           
        
        expect{
          Sidekiq::Testing.inline! do 
            post '/', b3, @make_signature.call(b3)
          end
        }.to change{User.where(fb_id:'4').first.state_table.last_story_read?}           
        
        expect(@s901).to receive(:run_sequence).with('6', :cookstory).and_call_original
        expect(@s901).to receive(:send_story)         

        puts "USER 6>>>>>>>>> #{User.where(fb_id:'6').first.to_hash}" 
        puts "USER 6 state >>>>>>>>> #{User.where(fb_id:'6').first.state_table.to_hash}"  
        expect{
          Sidekiq::Testing.inline! do 
            post '/', b4, @make_signature.call(b4)
          end
        }.to change{User.where(fb_id:'6').first.state_table.last_story_read?}           
        

        # and now we fast-forward by one day, whereby we expect no stories to be
        # sent because as of July 18 2016, we enforce stories on MWF only. This will
        # need to change at some point.   
        
        # move to saturday, we will change this spec at somepoint, but expect nothing
        # to be sent out!
        Timecop.freeze(Time.new(2016, 6, 25, 23, 0, 0, 0))        
        
        expect(@s900).not_to receive(:run_sequence)       
        expect(@s901).not_to receive(:run_sequence)
        expect(@s902).not_to receive(:run_sequence)
        expect(@s903).not_to receive(:run_sequence)
        expect(@s904).not_to receive(:run_sequence)

        puts "starting the clock again! we expect no stories<<<<<<<<<<<<<\n\n\n"
        expect{
          Sidekiq::Testing.fake! do
            @sw.perform (@time_range/2)
          end
          ScheduleWorker.drain
        }.not_to change{StartDayWorker.jobs.size}       
        
        Sidekiq::Worker.clear_all

        # move to Monday! Stories be coming out!
        # we would expect fb_ids [1,7] to be recieving something
        Timecop.freeze(Time.new(2016, 6, 27, 23, 0, 0, 0))        
        
        expect{
          Sidekiq::Testing.fake! do
            @sw.perform (@time_range/2)
          end
          ScheduleWorker.drain
        }.to change{StartDayWorker.jobs.size}.by 7  

      end

      # this is basically a compressed version of the last one. I was having stubbing issues.
      it 'does this correctly', thing:true do
        # 4 ppl read yesterday (story 900)
        4.times do |i| 
          User.where(fb_id:(i+1).to_s).first.state_table.update(last_story_read?: true)
        end       

        allow_any_instance_of(ScheduleWorker).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
          original_method.call(*args, [1,3,5], &block)
        end

        allow(@s901).to      receive(:run_sequence).exactly(3).times
        allow(@s902).to      receive(:run_sequence).exactly(4).times        

        # run the the clock
        expect{
          Sidekiq::Testing.inline! do
            @sw.perform (@time_range/2)
          end
        }.not_to change{User.where(fb_id:@late_users[0].fb_id)
                        .first.state_table
                        .story_number}

        # So at this point, users 5-7 have gotten :init from s901
        # and users 1-4 have gotten :init from s902. What we're 
        # gonna do now is have user's {[2,4]U[6]} press the 
        # story buttons from their respective days.


        b1 = @make_story_btn_press.call('2', @s902, :scratchstory)
        b2 = @make_story_btn_press.call('3', @s902, :scratchstory)
        b3 = @make_story_btn_press.call('4', @s902, :scratchstory)
        b4 = @make_story_btn_press.call('6', @s901, :cookstory)

        allow(@s902).to receive(:run_sequence).with('2', :scratchstory).and_call_original
        allow(@s902).to receive(:run_sequence).with('3', :scratchstory).and_call_original
        allow(@s902).to receive(:run_sequence).with('4', :scratchstory).and_call_original
        allow(@s902).to receive(:send_story).exactly(3).times     

        expect{
          Sidekiq::Testing.inline! do 
            puts "POST DAT SHIT\n\n\n\n\n"
            post '/', b1, @make_signature.call(b1)
          end
        }.to change{User.where(fb_id:'2').first.state_table.last_story_read?}
        
        expect{
          Sidekiq::Testing.inline! do 
            post '/', b2, @make_signature.call(b2)
          end
        }.to change{User.where(fb_id:'3').first.state_table.last_story_read?}           
        
        expect{
          Sidekiq::Testing.inline! do 
            post '/', b3, @make_signature.call(b3)
          end
        }.to change{User.where(fb_id:'4').first.state_table.last_story_read?}           
        
        allow(@s901).to receive(:run_sequence).with('6', :cookstory).and_call_original
        allow(@s901).to receive(:send_story)                
        expect{
          Sidekiq::Testing.inline! do 
            post '/', b4, @make_signature.call(b4)
          end
        }.to change{User.where(fb_id:'6').first.state_table.last_story_read?}           
        

        # and now we fast-forward by one day, whereby we expect no stories to be
        # sent because as of July 18 2016, we enforce stories on MWF only. This will
        # need to change at some point.   
        
        # move to saturday, we will change this spec at somepoint, but expect nothing
        # to be sent out!
        Timecop.freeze(Time.new(2016, 6, 25, 23, 0, 0, 0))        

        puts "starting the clock again! we expect no stories<<<<<<<<<<<<<\n\n\n"
        expect{
          Sidekiq::Testing.fake! do
            @sw.perform (@time_range/2)
          end
          ScheduleWorker.drain
        }.not_to change{StartDayWorker.jobs.size}       
        
        Sidekiq::Worker.clear_all

        # move to Monday! Stories be coming out!
        # we would expect fb_ids [1,7] to be recieving something
        Timecop.freeze(Time.new(2016, 6, 27, 23, 0, 0, 0))        
        
        expect{
          Sidekiq::Testing.fake! do
            @sw.perform (@time_range/2)
          end
          ScheduleWorker.drain
        }.to change{StartDayWorker.jobs.size}.from(0).to 7  

        # # we now expect [1] to get 902, [2,4] to get 903, [5] to get 901, [6] 902, [7] to get 901
        expect(@s900).not_to receive(:run_sequence)       
        allow(@s901).to      receive(:run_sequence).with(anything(), :init).exactly(2).times
        allow(@s902).to      receive(:run_sequence).with(anything(), :init).exactly(2).times
        allow(@s903).to      receive(:run_sequence).with(anything(), :init).exactly(3).times
        expect(@s904).not_to receive(:run_sequence)
        Sidekiq::Testing.fake! do
          StartDayWorker.drain
        end
      end


      it 'deals with curriculum version correctly', versioning:true do
        # hokay, so everyone should start on day 901.
        #
        # we're gonna set users [5,6] to be on currculum 667
        # and we're gonna set user [2,3] to be on curriculum 
        # 668. All else on 666 >:)
        @on_time_users.each do |u|
          u.state_table.update(story_number:901)
        end
        @on_time_users[4].update(curriculum_version: 667)
        @on_time_users[5].update(curriculum_version: 667)
        @on_time_users[1].update(curriculum_version: 668)
        @on_time_users[2].update(curriculum_version: 668)
        
        expect(@s900).not_to receive(:run_sequence)       
        allow(@s901).to      receive(:run_sequence).with(anything(), :init).exactly(7).times

        Sidekiq::Testing.inline! do
          @sw.perform (@time_range/2)
        end

        bodies = []

        # we're gonna have all users but usr 1 request a story
        (@num_ontime-1).times do |x|
          bodies << @make_story_btn_press.call((x+2).to_s, @s901, :cookstory)
        end
        
        # send a story to everyone but user #1
        allow(@s901).to receive(:run_sequence).with(anything(), :cookstory)
                    .and_call_original.exactly(7).times
        # version 666
        allow(@s901).to receive(:send_story)
                    .with(hash_including(:recipient, :library, :num_pages, :title => 'bird'))
                    .exactly(2).times
        # version 667
        allow(@s901).to receive(:send_story)
                    .with(hash_including(:recipient, :library, :num_pages, :title => 'scratch'))
                    .exactly(2).times
        # version 668
        allow(@s901).to receive(:send_story)
                    .with(hash_including(:recipient, :library, :num_pages, :title => 'coon'))
                    .exactly(2).times

        bodies.each do |b|
          Sidekiq::Testing.inline! do 
            post '/', b, @make_signature.call(b)
          end       
        end         

        # move to Monday
        Timecop.freeze(Time.new(2016, 6, 27, 23, 0, 0, 0))

        # so now we send the stories out again, and we expect different scripts
        # to be activated

        expect(@s900).not_to receive(:run_sequence)       
        allow(@s901).to      receive(:run_sequence).with(anything(), :init).exactly(1).times
        allow(@s902).to      receive(:run_sequence).with(anything(), :init).exactly(6).times

        # run the clock
        Sidekiq::Testing.inline! do
          @sw.perform (@time_range/2)
        end   


        # and now we simulates users [1,7] requesting the story!
        bodies2 = []
        bodies2 << @make_story_btn_press.call((1).to_s, @s901 , :cookstory)

        (@num_ontime-1).times do |x|
          bodies2 << @make_story_btn_press.call((x+2).to_s, @s902 , :scratchstory)
        end     


        allow(@s901).to receive(:run_sequence).with(anything(), :cookstory)
                    .and_call_original

        allow(@s902).to receive(:run_sequence).with(anything(), :cookstory)
                    .and_call_original.exactly(6).times

        # version 666
        allow(@s901).to receive(:send_story)
                    .with(hash_including(:recipient, :library, :num_pages, :title => 'bird'))

        allow(@s902).to receive(:send_story)
                    .with(hash_including(:recipient, :library, :num_pages, :title => 'coon'))
                    .exactly(2).times
        # version 667
        allow(@s902).to receive(:send_story)
                    .with(hash_including(:recipient, :library, :num_pages, :title => 'bird'))
                    .exactly(2).times
        # version 668
        allow(@s902).to receive(:send_story)
                    .with(hash_including(:recipient, :library, :num_pages, :title => 'scratch'))
                    .exactly(2).times

        bodies.each do |b|
          Sidekiq::Testing.inline! do 
            post '/', b, @make_signature.call(b)
          end       
        end   
      end

    end

    # this is basically a compressed version of the last one. I was having stubbing issues.
    it 'correctly transitions from day1 to day2', day1:true do

      # we have @ontime_user number of brand new users!

      @on_time_users.each do |u|
        u.reload()
        u.state_table.update story_number: 1 
      end

      @s1 = Birdv::DSL::ScriptClient.scripts['day1']
      @s2 = Birdv::DSL::ScriptClient.scripts['day2']
      
      allow_any_instance_of(ScheduleWorker).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [1,3,5], &block)
      end
      

      bodies = []

      # only 6 users request the thang
      (@num_ontime-1).times do |x|
        bodies[x]  =  @make_story_btn_press.call("#{x+1}", @s1, :greeting)
      end


      expect(@s1).to receive(:send_story).and_return(nil).exactly(6).times
      allow(@s1).to receive(:fb_send_json_to_user).and_return(nil)

      # the scenario is that when theh user clicks 'get_started', they get a
      # sequence that sends that story. This means that 6 ppl should get
      # a read_yesterday_story state_table field set to true.
      Sidekiq::Testing.fake! do 
        bodies.each do |b|
            post '/', b, @make_signature.call(b)
        end
      end
      BotWorker.drain

      expect(StateTable.where(last_story_read?:true).count).to eq(@num_ontime-1)

      # move to next Thrusday! Stories be coming out!
      # we would expect fb_ids [1,7] to be recieving something
      Timecop.freeze(Time.new(2016, 6, 30, 23, 0, 0, 0))        
      
      expect{
        Sidekiq::Testing.fake! do
          @sw.perform (@time_range/2)
        end
        ScheduleWorker.drain
      }.to change{StartDayWorker.jobs.size}.from(0).to 7  


      allow(@s1).to      receive(:run_sequence).with(anything(), :init)
      allow(@s2).to      receive(:run_sequence).with(anything(), :init).exactly(@num_ontime-1).times

      Sidekiq::Testing.fake! do
        StartDayWorker.drain
      end
    end


  end




    # 'postback' => {
    #   'payload' => 'USER_DEFINED_PAYLOAD'
    # }

end


  # this is from facebook/messenger server_spec.rb:
  # :::::::::::::::::::::::::::::::::::::::::::::::
  # context 'integrity check' do
  #   before do
  #     Facebook::Messenger.config.app_secret = '__an_insecure_secret_key__'
  #   end

  #   after do
  #     Facebook::Messenger.config.app_secret = nil
  #   end

  #   it 'do not trigger if fails' do
  #     expect(Facebook::Messenger::Bot).to_not receive(:trigger)

  #     post '/', {}, 'HTTP_X_HUB_SIGNATURE' => 'sha1=64738239'
  #   end

  #   it 'triggers if succeeds' do
  #     expect(Facebook::Messenger::Bot).to receive(:trigger)

  #     body = JSON.generate(
  #       object: 'page',
  #       entry: [
  #         {
  #           id: '1',
  #           time: 145_776_419_824_6,
  #           messaging: [
  #             {
  #               sender: {
  #                 id: '2'
  #               },
  #               recipient: {
  #                 id: '3'
  #               },
  #               timestamp: 145_776_419_762_7,
  #               message: {
  #                 mid: 'mid.1457764197618:41d102a3e1ae206a38',
  #                 seq: 73,
  #                 text: 'Hello, bot!'
  #               }
  #             }
  #           ]
  #         }
  #       ]
  #     )

  #     signature = OpenSSL::HMAC.hexdigest(
  #       OpenSSL::Digest.new('sha1'),
  #       Facebook::Messenger.config.app_secret,
  #       body
  #     )

  #     post '/', body, 'HTTP_X_HUB_SIGNATURE' => "sha1=#{signature}"
  #   end

  #   it 'returns bad request if signature is not present' do
  #     begin
  #       old_stream = $stderr.dup
  #       $stderr.reopen('/dev/null')
  #       $stderr.sync = true

  #       post '/', {}
  #     ensure
  #       $stderr.reopen(old_stream)
  #       old_stream.close
  #     end

  #     expect(last_response.status).to eq(400)
  #     expect(last_response.body).to eq('Error getting integrity signature')
  #     expect(last_response['Content-Type']).to eq('text/plain')
  #   end

  #   it 'returns bad request if signature is invalid' do
  #     post '/', {}, 'HTTP_X_HUB_SIGNATURE' => 'sha1=64738239'

  #     expect(last_response.status).to eq(400)
  #     expect(last_response.body).to eq('Error checking message integrity')
  #     expect(last_response['Content-Type']).to eq('text/plain')
  #   end
  # end