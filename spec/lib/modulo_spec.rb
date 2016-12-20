require 'spec_helper'
require 'bot/dsl'
require 'bot/curricula'
require 'timecop'
require 'workers'

describe 'modulo stories' do
  context "reminders" do


    before(:each) do
      # clean everything up
      # DatabaseCleaner.clean
      Sidekiq::Worker.clear_all

      @time = Time.new(2016, 6, 22, 23, 0, 0, 0) # with 0 utc-offset
      @time_range = 10.minutes.to_i
      @interval = @time_range / 2.0               
      Timecop.freeze(@time)

      @sw = ScheduleWorker.new
      @startday = StartDayWorker.new

      # Time.now is @time
      @on_time = User.create(:send_time => @time, fb_id: "12345")
      # @just_early = User.create(:send_time => @time - @interval, fb_id: "23456")
      # @just_late = User.create(:send_time => @time + (@interval-1.minute) + 59.seconds, fb_id: "34567")

      @users = [@on_time]

        # before each example, the user has already read day1!
      @users.each do |u|
        u.update(curriculum_version:666)
        # u.state_table.update(story_number:1)
        # u.state_table.update(last_story_read?:true)
        u.reload()
      end

      @day4 = Birdv::DSL::ScriptClient.scripts['fb']['day4']
      @remind_script = Birdv::DSL::ScriptClient.scripts['fb']['remind']

    end

    after(:each) do
      Timecop.return
    end

    def configure_shit
      allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args|
        original_method.call(*args, [Time.now.wday])
      end
      allow(@day4).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
        puts "running sequence for @day4"
        recipient, sequence_name = args
        puts "args = #{args}"
        puts "help me, please!"
        u = User.where(fb_id:recipient).first
        if u then # u might not exist because it's a demo
          u.state_table.update(last_sequence_seen: sequence_name.to_s)
        end
      end
      allow(@day4).to receive(:send).and_wrap_original do |original_method, *args|
        puts "send() for @day4"
        fb_id, to_send = args
        if is_story?(to_send)
          to_send.call(fb_id)
        elsif to_send.is_a? Hash
          puts "sending to #{fb_id}.... blech"
        end
      end

      allow(@day4).to receive(:story).and_wrap_original do |original_method, *args|
        puts "sending story for @day4"
        recipient = args[0]
        User.where(fb_id:recipient).first.state_table.update(
                                          last_story_read_time:Time.now.utc, 
                                          last_story_read?: true,
                                          last_unique_story_read?: true
                                          )
      
      end
    end

    def update_user
      @on_time.state_table.update(last_sequence_seen: "init", story_number: 9)
      @on_time.state_table.update(last_script_sent_time: @time,
                                  last_unique_story: 4,
                                  last_unique_story_read?: false)
      @on_time.reload
      @on_time.state_table.reload
    end

    # must configure for unique sequences........
    # user is at story 8
    # story count = 4
    # last_unique_story = 4
    # last_unique_story_read? = false

    it "should remind these users if they haven't pressed their buttons for day4" do

      configure_shit()
      update_user()
      Timecop.freeze(@time + 5.days)

      expect(@startday.remind?(@on_time)).to eq true

      expect(@remind_script).to receive(:run_sequence).with(@on_time.fb_id, :remind)

      expect(@day4).to receive(:run_sequence).with(@on_time.fb_id, :storybutton)

      Sidekiq::Testing.inline! do
        @sw.perform(@interval)
      end
      @on_time.reload()
      expect(@on_time.state_table.last_reminded_time).to eq Time.now
      expect(@on_time.state_table.num_reminders).to eq 1
      puts "state table after remind = #{@on_time.state_table.inspect}"

    end

    it "should unsubscribe users after 10 days of no signal" do
      configure_shit()
      update_user()
      @on_time.state_table.update(last_reminded_time: @time + 5.days, num_reminders: 1)
      Timecop.freeze(@time + 11.days)

      expect(@startday.remind?(@on_time)).to eq true
      expect(@remind_script).to receive(:run_sequence).with(@on_time.fb_id, :unsubscribe)

      Sidekiq::Testing.inline! do
        @sw.perform(@interval)
      end

      @on_time.reload
      @on_time.state_table.reload
      expect(@on_time.state_table.subscribed?).to eq false

      puts "that state table though #{@on_time.state_table.inspect}"
    end

  end

  context "resubscribing" do
    before (:each) do
      @sw = StartDayWorker.new
      @mw = MessageWorker.new
      @fb_id = 'my_fb_id'
      @user = User.create(fb_id: @fb_id)
      # this user is unsubscribed and has already received reminders....
      @user.state_table.update(last_story_read?:false, subscribed?:false)

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "calling run_sequence with #{args}"
      end
    end
  end

  context "start day worker" do 
    before(:each) do
      @sw = StartDayWorker.new
      @fb_id = 'my_fb_id'
      @user = User.create(fb_id: @fb_id)
      @user.state_table.update(last_story_read?:true, subscribed?:true)

      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:run_sequence).and_wrap_original do |original_method, *args, &block|
        puts "calling run_sequence with #{args}"
      end
    end

    context "user has less than total stories" do

        it "updates last_unique_story when getting a new story" do
          $story_count = 5
          @user.state_table.update(story_number: 0)

          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.to change{@user.state_table.last_unique_story}.to 1

          expect(@user.story_number).to eq 1
        end

        it "sends a story the normal way" do
          $story_count = 5
          @user.state_table.update(story_number: 0)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day1']).to receive(:run_sequence).once

          Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
          end

          expect(@user.story_number).to eq 1
        end
    end

    context "user has more than total stories and no new stories" do

        it "does not update last_unique_story when getting an old story" do
          # $story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*").inject(0) {|sum, n| /\d+\.rb/.match n ? sum+1 : sum }
          $story_count = 5
          @user.state_table.update(story_number: 7, last_unique_story: 5)
          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.not_to change{@user.state_table.last_unique_story}


        end

        it "sends the correct modulo story" do
          $story_count = 5
          # we have story 7 going INTO this...
          @user.state_table.update(story_number: 7, last_unique_story: 5)

          # should this send day4 instead of day3? what's the last story that was sent?

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day4']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end

          expect(@user.story_number).to eq 8

        end

        it "updates state_table fields correctly: last_story_read?, story_number" do

        end


        it "chooses day2 when mod is 1" do
          $story_count = 6
          @user.state_table.update(story_number: 11, last_unique_story: 6)
          expect(Birdv::DSL::ScriptClient.scripts['fb']['day2']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end

          expect(@user.story_number).to eq 12


        end

    end


    context "user has more than total stories and there is one new story" do

        it "updates last_unique_story when getting an old story" do
          # $story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*").inject(0) {|sum, n| /\d+\.rb/.match n ? sum+1 : sum }
          $story_count = 6
          @user.state_table.update(story_number: 7, last_unique_story: 5)
          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.to change{@user.state_table.last_unique_story}.to 6


        end

        it "sends the correct modulo story" do
          $story_count = 6
          @user.state_table.update(story_number: 7, last_unique_story: 5)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day6']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end

          expect(@user.story_number).to eq 7

        end


        it "updates last_unique_story when getting an old story 2" do
          # $story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*").inject(0) {|sum, n| /\d+\.rb/.match n ? sum+1 : sum }
          $story_count = 6
          @user.state_table.update(story_number: 7, last_unique_story: 3)
          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.to change{@user.state_table.last_unique_story}.to 4

          expect(@user.story_number).to eq 7


        end

        it "sends the correct modulo story 2" do
          $story_count = 6
          @user.state_table.update(story_number: 7, last_unique_story: 3)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day4']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end

          expect(@user.story_number).to eq 7

        end


    end


    context "user has more than total stories and there are many new stories" do

        it "updates last_unique_story when getting an old story" do
          # $story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*").inject(0) {|sum, n| /\d+\.rb/.match n ? sum+1 : sum }
          $story_count = 6
          @user.state_table.update(story_number: 10, last_unique_story: 3)
          expect {
            Sidekiq::Testing.inline! do
              @sw.perform(@fb_id, 'fb')
              @user.reload
            end
          }.to change{@user.state_table.last_unique_story}.to 4
          expect(@user.story_number).to eq 10


        end

        it "sends the correct modulo story" do
          $story_count = 6
          @user.state_table.update(story_number: 10, last_unique_story: 3)

          expect(Birdv::DSL::ScriptClient.scripts['fb']['day4']).to receive(:run_sequence).once
          Sidekiq::Testing.inline! do
            @sw.perform(@fb_id, 'fb')
            @user.reload
          end
          expect(@user.story_number).to eq 10

        end


    end



  end


  # context 'global variable story_count' do
  #   it 'is accessible by the user object' do
  #     my_story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*")
  #       .inject(0) do |sum, n|
  #                   if /\d+\.rb/.match n
  #                     sum + 1
  #                   else  
  #                     sum
  #                   end
  #                 end

  #     puts $story_count
  #     expect($story_count).to eq my_story_count    
  #     expect($story_count).to_not eq 0
  #   end
  # end
end
