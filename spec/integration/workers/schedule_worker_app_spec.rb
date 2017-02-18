require 'spec_helper'
require 'timecop'
require 'active_support/time'
require 'workers/schedule_worker'
require 'bot/dsl'
require 'bot/curricula'

describe ScheduleWorker do
  before(:each) do
    # clean everything up
    # DatabaseCleaner.clean
    Sidekiq::Worker.clear_all

    @time = Time.new(2016, 6, 22, 23, 0, 0, 0) # with 0 utc-offset
    @time_range = 10.minutes.to_i
    @interval = @time_range / 2.0
    Timecop.freeze(@time)

    @s = ScheduleWorker.new

    @story_num = 2

    # Time.now is @time
    @on_time = User.create(:send_time => @time, fb_id: "12345")

    # 6:55:00
    @just_early = User.create(:send_time => @time - @interval, fb_id: "23456")

    #  7:04:59pm
    @just_late = User.create(:send_time => @time + (@interval-1.minute) + 59.seconds, fb_id: "34567")

    # 6:54:59
    @early = User.create(:send_time => @time - (@interval+1.minute) + 59.seconds, fb_id: "45678")

    # 7:05
    @late = User.create(:send_time => @time + @interval, fb_id: "56789")

    @on_time.state_table.update(story_number: @story_num)
    @just_early.state_table.update(story_number: @story_num)
    @just_late.state_table.update(story_number: @story_num)
    @early.state_table.update(story_number: @story_num)
    @late.state_table.update(story_number: @story_num)

    @users = [@on_time, @just_early, @just_late, @early, @late]
    $story_count = 1000

  end

  after(:each) do
    Timecop.return
  end

  context "app users", app:true do
    before(:each) do
      @users.each do |u|
        case u.id % 3
        when 0
          u.update(platform: 'app', fcm_token: 'fun')
        when 1
          u.update(platform: 'android', fcm_token: 'fun')
        when 2
          u.update(platform: 'ios', fcm_token: 'fun')
        end

        u.reload
      end
    end


    it "calls StartDayWorker the correct number of times" do
      sw =  ScheduleWorker.new
      allow(sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [Time.now.wday], &block)
      end
      expect(ScheduleWorker.jobs.size).to eq(0)

      Sidekiq::Testing.fake! do
        expect {
         sw.perform(@interval)
          ScheduleWorker.drain
        }.to change(StartDayWorker.jobs, :size).by(3)
      end
    end


    it "increments story_number the correct number of times (StartDayWorker)" do

      sw =  ScheduleWorker.new
      allow(sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [Time.now.wday], &block)
      end
      expect(ScheduleWorker.jobs.size).to eq(0)

      Sidekiq::Testing.fake! do
        sw.perform(@interval)
        ScheduleWorker.drain
      end

      Sidekiq::Testing.fake! do
        StartDayWorker.drain
      end


      expect(@on_time.reload().state_table.story_number).to eq(@story_num +1)
      expect(@early.reload().state_table.story_number).to eq(@story_num)
      expect(@just_early.reload().state_table.story_number).to eq(@story_num + 1)
    end

  end



end
