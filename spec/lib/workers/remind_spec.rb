require 'spec_helper'
require 'timecop'
require 'active_support/time'
require 'workers/schedule_worker'
require 'bot/dsl'
require 'bot/curricula'

describe "Reminders" do

  before(:all) do
    Birdv::DSL::ScriptClient.clear_scripts 

    Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_scripts/*")
      .each {|f| load f }

    @remind_script = Birdv::DSL::ScriptClient.scripts['fb']['remind']

    @day1 = Birdv::DSL::ScriptClient.scripts['fb']['day1']
    @day2 = Birdv::DSL::ScriptClient.scripts['fb']['day2']
    @day4 = Birdv::DSL::ScriptClient.scripts['fb']['day4']

    dir = "#{File.expand_path(File.dirname(__FILE__))}/worker_test_curricula/"
    @c  = Birdv::DSL::Curricula.load(dir, absolute=true) 
    # allow(@day2).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
    #   puts "run_sequence for @day2"
    # end
    # allow(@remind_script).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
    #   puts "run_sequence for @remind_script"
    # end

  end

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

  end

  after(:each) do
    Timecop.return
  end

  def configure_shit
    allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args|
      original_method.call(*args, [Time.now.wday])
    end
    allow(@day1).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
      puts "running sequence for @day1"
      recipient, sequence_name = args
      puts "args = #{args}"
      puts "help me, please!"
      u = User.where(fb_id:recipient).first
      if u then # u might not exist because it's a demo
        u.state_table.update(last_sequence_seen: sequence_name.to_s)
      end
    end
    allow(@day1).to receive(:send).and_wrap_original do |original_method, *args|
      puts "send() for @day1"
      fb_id, to_send = args
      if is_story?(to_send)
        to_send.call(fb_id)
      elsif to_send.is_a? Hash
        puts "sending to #{fb_id}.... blech"
      end
    end

    allow(@day1).to receive(:story).and_wrap_original do |original_method, *args|
      puts "sending story for @day1"
      recipient = args[0]
      User.where(fb_id:recipient).first.state_table.update(
                                        last_story_read_time:Time.now.utc, 
                                        last_story_read?: true)

    end
    allow(@day2).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
      puts "running sequence for @day2"
      recipient, sequence_name = args
      puts "args = #{args}"
      puts "help me, please!"
      u = User.where(fb_id:recipient).first
      if u then # u might not exist because it's a demo
        u.state_table.update(last_sequence_seen: sequence_name.to_s)
      end
    end
    allow(@day2).to receive(:send).and_wrap_original do |original_method, *args|
      puts "send() for @day2"
      fb_id, to_send = args
      if is_story?(to_send)
        to_send.call(fb_id)
      elsif to_send.is_a? Hash
        puts "sending to #{fb_id}.... blech"
      end
    end

    allow(@day2).to receive(:story).and_wrap_original do |original_method, *args|
      puts "sending story for @day2"
      recipient = args[0]
      User.where(fb_id:recipient).first.state_table.update(
                                        last_story_read_time:Time.now.utc, 
                                        last_story_read?: true)
    
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
                                        last_story_read?: true)
    
    end

  end

  def update_user
    @on_time.state_table.update(last_sequence_seen: "init", story_number: 1)
    @on_time.state_table.update(last_script_sent_time: @time)
    @on_time.reload
    @on_time.state_table.reload
  end

  it 'should send the first story when the user does not exist at all through startdayworker', ass:true do
    configure_shit()
    User.each {|u| u.destroy }
    
    expect(User.count).to eq 0

    Sidekiq::Testing.inline! do
      StartDayWorker.perform_async('my asshole', 'fb')
    end

    expect(User.count).to eq 1
    puts "#{User.first.inspect}"
    puts "#{User.first.state_table.inspect}"

  end

  it "should send the first day's button" do 
    configure_shit()
    puts "story_number = #{@on_time.state_table.story_number}"
    Sidekiq::Testing.inline! do 
      # expect(StartDayWorker).to receive(:perform_async).exactly(@users.size).times
      expect(@day1).to receive(:run_sequence).exactly(@users.size).times
      @sw.perform(@interval)
    end

  end

  it "should not remind users if it's been under four days since they last read their story" do
    configure_shit()
    update_user()

    Timecop.freeze(@time + 2.days)

    expect(@startday.remind?(@on_time)).to eq false
    expect(@day1).not_to receive(:run_sequence)
    expect(@remind_script).not_to receive(:run_sequence)

    Sidekiq::Testing.inline! do
      @sw.perform(@interval)
    end
  end 

  it "should remind these users if they haven't pressed their buttons for day1" do
    configure_shit()
    update_user()
    Timecop.freeze(@time + 5.days)

    expect(@startday.remind?(@on_time)).to eq true

    expect(@remind_script).to receive(:run_sequence).with(@on_time.fb_id, :remind)

    Sidekiq::Testing.inline! do
      @sw.perform(@interval)
    end
    @on_time.reload()
    expect(@on_time.state_table.last_reminded_time).to eq Time.now
    expect(@on_time.state_table.num_reminders).to eq 1
    puts "state table after remind = #{@on_time.state_table.inspect}"
  end

  it "should not remind users again after they've already gotten a reminder" do
    configure_shit()
    update_user()
    @on_time.state_table.update(last_reminded_time: @time + 5.days, num_reminders: 1)
    Timecop.freeze(@time + 7.days)

    expect(@startday.remind?(@on_time)).to eq true
    expect_any_instance_of(Birdv::DSL::StoryTimeScript).not_to receive(:run_sequence)

    Sidekiq::Testing.inline! do
      @sw.perform(@interval)
    end
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

  it "should resubscribe after receiving the resubscribe postback" do
    configure_shit()
    update_user()

    @on_time.state_table.update(last_reminded_time: @time + 5.days, 
                                num_reminders: 1,
                                subscribed?: false,
                                last_story_read?: false
                                )
    Timecop.freeze(@time + 12.days)
    @on_time.reload()
    @on_time.state_table.reload()
    previous_story_number = @on_time.state_table.story_number
    puts "previous_story_number = #{previous_story_number}"

    load 'sequence_scripts/remind.rb'
    real_remind_sript = Birdv::DSL::ScriptClient.scripts['fb']['remind']

    allow(real_remind_sript).to  receive(:send).and_wrap_original do |original_method, *args|
      puts "sending to #{args[0]}"
    end

    real_remind_sript.run_sequence(@on_time.fb_id, :resubscribe)
    @on_time.reload()
    @on_time.state_table.reload()
    expect(@on_time.state_table.subscribed?).to eq true
    expect(@on_time.state_table.story_number).to eq (previous_story_number)
    expect(@on_time.state_table.last_story_read?).to eq true
    expect(@on_time.state_table.last_script_sent_time).to be_nil
    expect(@on_time.state_table.last_reminded_time).to be_nil
    puts "the state table of the ages = #{@on_time.state_table.inspect}"
    # expect the num_reminders to reset
  end

  context "the next story, day2" do
    before(:all) do
      Birdv::DSL::ScriptClient.clear_scripts 
      Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_scripts/*").each {|f| load f }
      @remind_script = Birdv::DSL::ScriptClient.scripts['fb']['remind']
      @day1 = Birdv::DSL::ScriptClient.scripts['fb']['day1']
      @day2 = Birdv::DSL::ScriptClient.scripts['fb']['day2']
      @day4 = Birdv::DSL::ScriptClient.scripts['fb']['day4']
      puts "HERE LIE THE SCRIPTS!"
      puts "#{@remind_script.inspect}"
      puts "#{@day1.inspect}"
      puts "#{@day2.inspect}"
      puts "#{@day4.inspect}"
      dir = "#{File.expand_path(File.dirname(__FILE__))}/worker_test_curricula/"
      @c  = Birdv::DSL::Curricula.load(dir, absolute=true) 
    end
    before (:each) do
      configure_shit()
      @after_spatial_time = @time + 13.days
      Timecop.freeze(@after_spatial_time)
      @on_time.state_table.update(last_reminded_time: nil, 
                                  num_reminders: 0,
                                  subscribed?: true,
                                  last_story_read?: true,
                                  last_script_sent_time: nil, 
                                  last_sequence_seen: "resubscribe"
                                  )
    end

    it "should send day1 normally" do
      expect(@day1).to receive(:run_sequence).with(@on_time.fb_id, :init).once

      Sidekiq::Testing.inline! do
        @sw.perform(@interval)
      end


    end

    it "should send day2 normally" do
      configure_shit()
      @on_time.state_table.update(story_number:1)
      @day1.story(@on_time.fb_id)
      @on_time.reload()
      @on_time.state_table.reload()
      expect(@on_time.state_table.last_story_read?).to be true
      expect(@on_time.state_table.last_story_read_time).to eq Time.now

      Timecop.freeze(@after_spatial_time + 1.week)

      expect(@day2).to receive(:run_sequence).exactly(@users.size).times

      # expect(StartDayWorker).to receive(:perform_async)
      Sidekiq::Testing.inline! do
        @sw.perform(@interval)
      end

      @on_time.reload()
      @on_time.state_table.reload()
      puts "new state = #{@on_time.state_table.inspect}"

    end

  end

  context "another reminder for story 4" do
    before(:all) do
      Birdv::DSL::ScriptClient.clear_scripts 
      Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_scripts/*").each {|f| load f }
      @remind_script = Birdv::DSL::ScriptClient.scripts['fb']['remind']
      @day1 = Birdv::DSL::ScriptClient.scripts['fb']['day1']
      @day2 = Birdv::DSL::ScriptClient.scripts['fb']['day2']
      @day4 = Birdv::DSL::ScriptClient.scripts['fb']['day4']
      dir = "#{File.expand_path(File.dirname(__FILE__))}/worker_test_curricula/"
      @c  = Birdv::DSL::Curricula.load(dir, absolute=true) 
    end

    before(:each) do
      configure_shit()
      @after_spatial_time = Time.parse "2016-07-05 23:00:00 UTC"
      @now = @after_spatial_time + 1.week
      @on_time.state_table.update(last_story_read?:false,
                                  last_script_sent_time: @now,
                                  last_story_read_time: @now,
                                  last_sequence_seen: "init",
                                  story_number: 4
                                 )
      @on_time.reload()
      @on_time.state_table.reload()
    end

    it "doesn't send anything only a few days after" do
      Timecop.freeze(@now + 2.days)

      expect_any_instance_of(Birdv::DSL::StoryTimeScript).not_to receive(:run_sequence)

      Sidekiq::Testing.inline! do
        @sw.perform(@interval)
      end
    end

    it "should remind the user after 5 days of silence" do
      configure_shit()
      Timecop.freeze(@now + 5.days)

      expect(@startday.remind?(@on_time)).to eq true

      expect(@remind_script).to receive(:run_sequence).with(@on_time.fb_id, :remind)

      Sidekiq::Testing.inline! do
        @sw.perform(@interval)
      end

      @on_time.reload()
      expect(@on_time.state_table.last_reminded_time).to eq Time.now
      expect(@on_time.state_table.num_reminders).to eq 1
      puts "state table after remind = #{@on_time.state_table.inspect}"

    end

    it "should not remind users again after they've already gotten a reminder" do
      configure_shit()
      Timecop.freeze(@now + 7.days)

      @on_time.state_table.update(last_reminded_time: @now + 5.days, num_reminders: 1)


      expect(@startday.remind?(@on_time)).to eq true
      expect_any_instance_of(Birdv::DSL::StoryTimeScript).not_to receive(:run_sequence)

      Sidekiq::Testing.inline! do
        @sw.perform(@interval)
      end
    end
    it "should unsubscribe users after 10 days of no signal" do
      configure_shit()
      @on_time.state_table.update(last_reminded_time: @now + 5.days, num_reminders: 1)
      Timecop.freeze(@now + 11.days)

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

    it "should resubscribe after receiving the resubscribe postback" do
      configure_shit()

      @on_time.state_table.update(last_reminded_time: @now + 5.days, 
                                  num_reminders: 1,
                                  subscribed?: false,
                                  last_story_read?: false
                                  )
      Timecop.freeze(@now + 12.days)
      @on_time.reload()
      @on_time.state_table.reload()
      previous_story_number = @on_time.state_table.story_number
      puts "previous_story_number = #{previous_story_number}"

      load 'sequence_scripts/remind.rb'
      real_remind_sript = Birdv::DSL::ScriptClient.scripts['fb']['remind']

      allow(real_remind_sript).to  receive(:send).and_wrap_original do |original_method, *args|
        puts "sending to #{args[0]}"
      end

      real_remind_sript.run_sequence(@on_time.fb_id, :resubscribe)
      @on_time.reload()
      @on_time.state_table.reload()
      expect(@on_time.state_table.subscribed?).to eq true
      expect(@on_time.state_table.story_number).to eq (previous_story_number)
      expect(@on_time.state_table.last_story_read?).to eq true
      expect(@on_time.state_table.last_script_sent_time).to be_nil
      expect(@on_time.state_table.last_reminded_time).to be_nil
      puts "the state table of the ages = #{@on_time.state_table.inspect}"
      # expect the num_reminders to reset
    end

  end

end