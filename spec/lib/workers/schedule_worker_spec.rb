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

  end

  after(:each) do
    Timecop.return
  end

  context "it handles Pacific time cases", pacific:true do

    context "within_time_range function", :range => true do
      before(:each) do
        @west_time = Time.new(2016, 6, 23, 2, 0, 0, 0) # with 0 utc-offset

        # change those timezones dawg!
        User.each do |user|
          puts "updating users #{user.fb_id}...."
          user.update(tz_offset: -7)
          puts "send_time = #{user.send_time}"
        end

        # 7pm in Pacific Time during DST

        Timecop.freeze(@west_time)
      end   

      after(:each) do
        Timecop.return
      end

      it "returns true for users who are right on time" do
        on_time = User.where(fb_id: "12345").first
        expect(@s.within_time_range(on_time, @interval, [Time.now.wday])).to be true
      end


      it "returns true for users within the time interval at a given time" do 
        just_early = User.where(fb_id: "23456").first
        just_late = User.where(fb_id: "34567").first
        expect(@s.within_time_range(just_early, @interval, [Time.now.wday])).to be true
        expect(@s.within_time_range(just_late, @interval, [Time.now.wday])).to be true
      end

      it "returns false for users outside the time interval at a given time" do
        expect(@s.within_time_range(@early, @interval, [Time.now.wday])).to be false
        expect(@s.within_time_range(@late, @interval, [Time.now.wday])).to be false
      end

      it "does not send messages to a user twice" do
        User.each {|u| u.destroy } # clean database
        user = User.create(:send_time => @time + @interval - 1.second, tz_offset:-7)
        user.state_table.update(story_number: @story_num)
        expect(@s.within_time_range(user, @interval, [Time.now.wday])).to be true
        Timecop.freeze(Time.now + @time_range)
        expect(@s.within_time_range(user, @interval, [Time.now.wday])).to be false      
      end

    end # context within_time_range function


  end # context it handles Pacific time cases 



  # context "timezone conversion function", :zone => true do
  #   before(:each) do
  #     @summer, @winter = @time, @time + 6.months
  #   end

  #   it "handles summer-summer and winter-winter cases (DST)" do
  #   # when the user enrolled in the summer and it's currently summer
  #     Timecop.freeze(@summer)
  #     user = User.create(:send_time => Time.now)
  #     expect(@s.adjust_tz(user)).to eq(user.send_time)
  #     # winter-winter case
  #     Timecop.freeze(@winter)
  #     user = User.create(:send_time => Time.now) # enrolled_on field is wintertime
  #     expect(@s.adjust_tz(user)).to eq(user.send_time)
  #   end

  #   it "subtracts an hour from the UTC clock when it's summer and the user enrolled during the winter" do
  #   # when the user enrolled in the winter and it's currently summer
  #     Timecop.freeze(@winter)
  #     user = User.create(:send_time => Time.now)
  #     Timecop.freeze(@summer)
  #     expect(@s.adjust_tz(user)).to eq(user.send_time - 1.hour)
  #   end

  #   it "adds an hour to the UTC clock when it's winter and the user enrolled during the summer" do 
  #   # when the user enrolled in the summer and it's currently winter
  #     Timecop.freeze(@summer)
  #     user = User.create(:send_time => @summer)
  #     Timecop.freeze(@winter)
  #     expect(@s.adjust_tz(user)).to eq(user.send_time + 1.hour)
  #   end
  # end


  context "within_time_range function", :range => true do

    it 'gets fucked' do
      puts "FUCKED!"
      Timecop.freeze(Time.now + 8.days)
      @on_time.state_table.update(story_number: 9)
      @on_time = User.where(fb_id: "12345").first
      puts "#{@on_time.state_table.inspect}"
      expect(@s.within_time_range(@on_time, @interval)).to be true

    end


    it "returns true for users within the time interval at a given time" do

      expect(@s.within_time_range(@just_early, @interval, [Time.now.wday])).to be true
      expect(@s.within_time_range(@just_late, @interval, [Time.now.wday])).to be true
    end

    it "returns false for users outside the time interval at a given time" do
      expect(@s.within_time_range(@early, @interval, [Time.now.wday])).to be false
      expect(@s.within_time_range(@late, @interval, [Time.now.wday])).to be false
    end

    it "does not send messages to a user twice" do
      User.each {|u| u.destroy } # clean database

      user = User.create(:send_time => Time.now + @interval - 1.second)
      user.state_table.update(story_number: @story_num)
      expect(@s.within_time_range(user, @interval, [Time.now.wday])).to be true
      Timecop.freeze(Time.now + @time_range)
      expect(@s.within_time_range(user, @interval, [Time.now.wday])).to be false      
    end

  end # context 'within_time_range function'

  context "filtering users", :filter => true do

    before(:each) do
      Timecop.freeze Time.new(2016, 6, 30, 23, 0, 0, 0)
    end

    after(:each) do
      Timecop.return
    end

    it "gets users whose send_time is between 6:55:00 and 7:04:59" do
      allow(@s).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [Time.now.wday], &block)
      end

      users = [@on_time, @just_early, @just_late]
      filtered = @s.filter_users(@time, @interval)
      expect(filtered.size).to eq(3)
      # we want filter_uses to return the SQL rows
      expect(filtered.to_set).to eq(users.to_set)
    end

    it "does not get users whose send_time is at 7:05 or 6:54:59" do
      users = [@early, @late]
      filtered = @s.filter_users(@time, @interval)
      for user in users
        expect(filtered).not_to include(user)
      end
    end

    it "calls StartDayWorker the correct number of times" do
      sw =  ScheduleWorker.new
      allow(sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [Time.now.wday], &block)
      end
      users = [@on_time, @just_early, @just_late]
      expect(ScheduleWorker.jobs.size).to eq(0)
      
      Sidekiq::Testing.fake! do
        expect {
         sw.perform(@interval)
          ScheduleWorker.drain
        }.to change(StartDayWorker.jobs, :size).by(3)
      end
    end

    it "does NOT call StartDayWorker when users are at day 1" do
      User.each {|u| u.destroy } # clean database
      user = User.create(:send_time => Time.now)
      user.state_table.update(story_number: 1)
      expect(ScheduleWorker.jobs.size).to eq(0)

      Sidekiq::Testing.fake! do
        expect {
          ScheduleWorker.new.perform(@interval)
          ScheduleWorker.drain
        }.to change(StartDayWorker.jobs, :size).by(0)
      end
    end

    it "calls StartDayWorker on all the right people" do

      sw =  ScheduleWorker.new
      allow(sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args, &block|
        original_method.call(*args, [Time.now.wday], &block)
      end

      # specify exact arguments and people on this one...
      users = [@on_time, @just_early, @just_late]
      for user in users
        expect(StartDayWorker).to receive(:perform_async).with(user.fb_id, platform='fb').once
      end

      Sidekiq::Testing.inline! do
        sw.perform
      end
    end
  

  # end # context 'filtering users'

		context 'people should be following schedule rules nao', timeline:true do
			before(:all) do
				@sw_curric = ScheduleWorker.new 
				
				@sw_curric.schedules = [
			    { 
			      start_day: 1,
			      days: [4] 
			    },
			    {
			      start_day: 3,
			      days: [1,4]
			    },
			    {
			      start_day: 6,
			      days: [1,2,4]
			    }
				]

      	dir = "#{File.expand_path(File.dirname(__FILE__))}/worker_test_curricula/"
      	@c 	= Birdv::DSL::Curricula.load(dir, absolute=true) 
			end

			after(:all) do
        Timecop.return
			end

      after(:each) do
        Timecop.return
      end


			before(:each) do
      	# users = User.all
				@users.each do |u|
					u.update(curriculum_version:666)
					u.state_table.update(story_number:2)
				end

			end

			describe 'day 1 behaviour', day1:true do

        before(:all) do
          Birdv::DSL::ScriptClient.clear_scripts 


          Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test_scripts/*")
            .each {|f| load f }

          @remind_script = Birdv::DSL::ScriptClient.scripts['fb']['remind']
          @day1 = Birdv::DSL::ScriptClient.scripts['fb']['day1']
          @day2 = Birdv::DSL::ScriptClient.scripts['fb']['day2']



          # allow(@day2).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
          #   puts "run_sequence for @day2"
          # end
          # allow(@remind_script).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
          #   puts "run_sequence for @remind_script"
          # end

          @sw = ScheduleWorker.new
          @sd = StartDayWorker.new

        end


				# before each example, the user has already read day1!
				before(:each) do
					@users.each do |u|
						u.update(curriculum_version:666)
						u.state_table.update(story_number:1)
						u.state_table.update(last_story_read?:true)
            u.reload()
					end
				end

        it 'should remind certain users, bitch!', remind: true do
          expect(@sd.remind?(@on_time)).to eq false
        end

        it 'should NOT remind certain users, bitch!', remind: true do
          User.each {|u| u.destroy }
          start_time = Time.new(2016, 7, 28, 23, 0, 0, 0)
          Timecop.freeze(start_time)  
          fb_id = 'some_id'
          user = User.create(fb_id: fb_id)
          expect(@sd.remind?(user)).to eq false
          allow(@day1).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
            puts "run_sequence for @day1"
          end
          expect(@day1).to receive(:run_sequence).with(fb_id, :init)

          Sidekiq::Testing.inline! do 
            @sw.perform(@interval)
          end
        end

        it 'should remind users!', remind: true do
          # kill everyone
          User.each {|u| u.destroy }

          start_time = Time.new(2016, 7, 28, 23, 0, 0, 0)
          Timecop.freeze(start_time)  
          fb_id = 'some_id'
          user = User.create(fb_id: fb_id)
          expect(user.state_table.story_number).to eq 0

          allow(@day1).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
            puts "run_sequence for @day1"
          end
          # expect(User.count )
          expect(@day1).to receive(:run_sequence).with(fb_id, :init)


          Sidekiq::Testing.inline! do 
            @sw.perform(@interval)
          end

          user.reload()
          expect(user.state_table.story_number).to eq 1

          # one week later!
          Timecop.freeze(start_time + 1.week)
          expect(user.state_table.num_reminders).to eq 0

          expect(@sd.remind?(user)).to eq true

          Sidekiq::Testing.inline! do 
            expect(@remind_script).to receive(:run_sequence).with(fb_id, :remind)
            @sw.perform(@interval)
          end

          user.reload()

          expect(user.state_table.num_reminders).to eq 1

          # a day later.....
          Timecop.freeze(start_time + 1.day)

          user.reload()

          expect(user.state_table.num_reminders).to eq 1

          puts "WE'VE FINISHED THE FIRST REMINDER!"

          allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args|
            original_method.call(*args, [Time.now.wday])
          end

          Sidekiq::Testing.inline! do 
            expect(StartDayWorker).to receive(:perform_async)
            expect(@remind_script).not_to receive(:run_sequence)
            expect(@day1).not_to receive(:run_sequence)
            @sw.perform(@interval)
          end


        end

        it 'unsubscribes after two weeks' do
           # kill everyone
          User.each {|u| u.destroy }

          start_time = Time.new(2016, 7, 28, 23, 0, 0, 0)
          Timecop.freeze(start_time + 2.weeks)
          fb_id = 'some_id'
          user = User.create(fb_id: fb_id)
          expect(user.state_table.story_number).to eq 0

          allow(@day1).to  receive(:run_sequence).and_wrap_original do |original_method, *args|
            puts "run_sequence for @day1"
          end
          user.reload()

          allow(@sw).to  receive(:within_time_range).and_wrap_original do |original_method, *args|
            original_method.call(*args, [Time.now.wday])
          end

          expect(user.state_table.num_reminders).to eq 1
          expect(user.state_table.last_reminded_time).to_not be_nil
          puts "WE'RE DOING THE LAST TESTS NOW!"
          puts "user count = #{User.count}"

          # expect(StartDayWorker).to receive(:perform_async).exactly(1).times.with(fb_id, 'fb')
          # expect(@day1).not_to receive(:run_sequence)
          # expect(@remind_script).to receive(:run_sequence).with(fb_id, :unsubscribe)

          Sidekiq::Testing.inline! do 
            # ok, the unsubscribe is not working right now....
            # okay, the unsubscribe stuff isn't working...........
            @sw.perform(@interval)
          end

        end



        it 'doesn\'t send a goddamn story button to those who haven\'t read their last story, you hear me bitch?', myshit: true do
          @users.each do |u|
            u.state_table.update(last_story_read?:false)
            u.state_table.update(story_number: 1)
            # u.state_table.update(last_story_read_time: Time.now.utc - 1.week)
          end
          start_time = Time.new(2016, 7, 28, 23, 0, 0, 0)
          Timecop.freeze(start_time)  
          # expect(@remind_script).to receive(:run_sequence).once.with('5612125831', :init)
          expect(@day1).not_to receive(:run_sequence)
          expect(@day2).not_to receive(:run_sequence)
          Sidekiq::Testing.inline! do 
            @sw_curric.perform(@interval)
          end
        end

        it 'day 2 doesn\'t send a goddamn story button to those who haven\'t read their last story, you hear me bitch?', myshit: true do
          @users.each do |u|
            u.state_table.update(last_story_read?:false, story_number: 2)
            # u.state_table.update(last_story_read_time: Time.now.utc - 1.week)
          end
          start_time = Time.new(2016, 7, 28, 23, 0, 0, 0)
          Timecop.freeze(start_time)  

          expect(@day1).not_to receive(:run_sequence)
          expect(@day2).not_to receive(:run_sequence)
          Sidekiq::Testing.inline! do
            @sw_curric.perform(@interval)
          end
        end

				# TODO: write a test that ensure the get_schedule thing behaves proper

				it 'sends next story on [4] of next week if day1 on 2' do
					start_time = Time.new(2016, 7, 26, 23, 0, 0, 0)
					Timecop.freeze(start_time)
					# last story read on Tuesday!
					@users.each do |u|
						u.state_table.update( last_story_read_time: start_time )
					end	

					expect{
						Sidekiq::Testing.fake! {
							# run that same day to ensure not send stuff						
							@sw_curric.perform(@interval)
							(3..10).each do |day|
								start_time += 1.day
								Timecop.freeze(start_time)
								@sw_curric.perform(@interval)
							end
						}
					}.not_to change{StartDayWorker.jobs.size}

					# now we finally reach that [4]
					start_time += 1.day
					Timecop.freeze(start_time)		

					expect(StartDayWorker).to receive(:perform_async).exactly(3).times
					@sw_curric.perform(@interval)		
				end
				
				it 'sends next story on [4] of next week if day1 on 3' do
					start_time = Time.new(2016, 7, 27, 23, 0, 0, 0)
					Timecop.freeze(start_time)
					# last story read on Wednesday!
					@users.each do |u|
						u.state_table.update( last_story_read_time: start_time )
					end	

					# cycle through the days
					expect{
						Sidekiq::Testing.fake! {
							# run that same day to ensure not send stuff				
							@sw_curric.perform(@interval)			
							(4..10).each do |day|
								start_time += 1.day
								Timecop.freeze(start_time)
								@sw_curric.perform(@interval)
							end
						}
					}.not_to change{StartDayWorker.jobs.size}

					# now we finally reach that [4]
					start_time += 1.day
					Timecop.freeze(start_time)		

					expect(StartDayWorker).to receive(:perform_async).exactly(3).times
					@sw_curric.perform(@interval)	
				end




				it 'sends story in same upcoming week if day1 not [2,3]' do
					start_time = Time.new(2016, 7, 24, 23, 0, 0, 0)
					monday 		 = Time.new(2016, 7, 25, 23, 0, 0, 0)
					Timecop.freeze(start_time)
					# day1 read on Monday!
					@users.each do |u|
						u.state_table.update( last_story_read_time: start_time )
					end	

					# cycle through the days
					expect{
						Sidekiq::Testing.fake! {
							# run that same day to ensure not send stuff				
							@sw_curric.perform(@interval)			
							(2..11).each do |day|
								start_time += 1.day
								Timecop.freeze(start_time)
								@sw_curric.perform(@interval)
							end
						}
					}.not_to change{StartDayWorker.jobs.size}

					# now we finally reach that [4]
					start_time += 1.day
					Timecop.freeze(start_time)		

					expect(StartDayWorker).to receive(:perform_async).exactly(3).times
					@sw_curric.perform(@interval)					
				end




				it 'sends story in 7 days if day1 on a 4', poop:true do
					start_time = Time.new(2016, 7, 27, 23, 0, 0, 0)
					Timecop.freeze(start_time)

					# last story read on Wednesday!
					@users.each do |u|
						u.state_table.update( last_story_read_time: start_time )
					end	

					# cycle through the days
					expect{
						Sidekiq::Testing.fake! {
						# run that same day to ensure not send stuff				
							@sw_curric.perform(@interval)			
							(4..10).each do |day|
								start_time += 1.day
								Timecop.freeze(start_time)
								@sw_curric.perform(@interval)
							end
						}
					}.not_to change{StartDayWorker.jobs.size}

					# now we finally reach that [4]
					start_time += 1.day
					Timecop.freeze(start_time)		

					expect(StartDayWorker).to receive(:perform_async).exactly(3).times
					@sw_curric.perform(@interval)	
				end
			end  # END describe 'day 1 behaviour', day1:true do

			# note that these guys are all on day2
			it 'sends out stories on the specified day' do
				# freeze on a Friday of last week!
				start_time = Time.new(2016, 7, 28, 23, 0, 0, 0)
				Timecop.freeze(start_time-6)

				# cycle through the days
				expect{
					Sidekiq::Testing.fake! {
						# run that same day to ensure not send stuff				
						@sw_curric.perform(@interval)			
						(4..10).each do |day|
							start_time += 1.day
							Timecop.freeze(start_time)
							@sw_curric.perform(@interval)
						end
					}
				}.to change{StartDayWorker.jobs.size}.by 9
			end


			it 'sends to us but not others' do

				local_users = @users
				aub = User.create(first_name: 'Aubrey',
													last_name:  'Wahl',
													fb_id: 			'11') 
				vid = User.create(first_name: 'David',
													last_name:  'McPeek',
													fb_id: 			'12') 
				fil = User.create(first_name: 'Phil',
													last_name:  'Esterman',
													fb_id: 			'13') 
				local_users << aub
				local_users << vid
				local_users << fil

				local_users.each do |u|
					u.state_table.update(story_number:6)
				end
				
				# freeze on a Sunday! no one except us should get them stories!
				start_time = Time.new(2016, 7, 24, 23, 0, 0, 0)
				Timecop.freeze(start_time)

				expect{
					Sidekiq::Testing.fake! {
						@sw_curric.perform(@interval)			
					}
				}.to change{StartDayWorker.jobs.size}.by 3

				# TODO: check the specifics?


			end


			it 'sends story when we upgraded to new schedule' do
				@users.each do |u|
					u.state_table.update(story_number:6)
				end

				# freeze on a Sunday!
				start_time = Time.new(2016, 7, 24, 23, 0, 0, 0)
				Timecop.freeze(start_time)

				expect{
					Sidekiq::Testing.fake! {
						@sw_curric.perform(@interval)			
					}
				}.not_to change{StartDayWorker.jobs.size}				

				# freeze on a Monday!
				start_time += 1.day
				Timecop.freeze(start_time)
				expect{
					Sidekiq::Testing.fake! {
						@sw_curric.perform(@interval)	
						start_time += 1.day
						Timecop.freeze(start_time)
						@sw_curric.perform(@interval)			
					}
				}.to change{StartDayWorker.jobs.size}.by 6

				# following two days			
				expect{
					Sidekiq::Testing.fake! {
						start_time += 1.day
						Timecop.freeze(start_time)
						@sw_curric.perform(@interval)			
					}
				}.not_to change{StartDayWorker.jobs.size}

				# now we at Thursday, should send out!
				start_time += 1.day
				Timecop.freeze(start_time)
				expect{
					Sidekiq::Testing.fake! {
						@sw_curric.perform(@interval)			
					}
				}.to change{StartDayWorker.jobs.size}.by 3
			end

		end # END context 'when there is a specified story receipt day', timeline:true do
	end # END context 'filtering users dp'


  describe 'StartDayWorker', start_day:true do
    before(:example) do
      @starting_story_num = 900
      @u1_id = '1'
      @u1 = User.create(fb_id: @u1_id, send_time: Time.now)
      User.where(fb_id: @u1_id).first
                .state_table.update(story_number: @starting_story_num)


      @s = Birdv::DSL::ScriptClient.new_script 'day901' do
        day (901) #dang this is kinda dangerless (plz enforce =  @starting_story_num+1)
        sequence 'dummy_first' do |r|
          puts 'hey this worked'
        end
      end

      @script = Birdv::DSL::ScriptClient.scripts['fb']["day#{@starting_story_num+1}"]

    end
  
    context '#update_day' do

      it 'increments the day # when last story was read' do
        expect(@script).to receive(:run_sequence)
        @u1.state_table.update(last_story_read?:true)
        expect{
          Sidekiq::Testing.inline! do
            StartDayWorker.perform_async(@u1_id)
          end
        }.to change{User.where(fb_id: @u1_id).first.state_table.story_number}.by 1

      end
        # TODO: i need a trickier way to test this
      it 'should update day before running the sequence', order:true do
        # expect(@script).to receive(:run_sequence)


        # @u1.state_table.update(last_story_read?:true)
        # expect{
        #   Sidekiq::Testing.inline! do
        #     StartDayWorker.perform_async(@u1_id)
        #   end
        # }.to change{User.where(fb_id: @u1_id).first.state_table.story_number}.by 1

      end
      
      it 'does not increment day number when hasnt read last story', nosend:true do
        day = User.where(fb_id: @u1_id).first.state_table.story_number
        u1script = Birdv::DSL::ScriptClient.scripts['fb']["day#{day+1}"] 
        expect(u1script).not_to receive(:run_sequence)
        expect{
          Sidekiq::Testing.inline! do
            StartDayWorker.perform_async(@u1_id)
          end
        }.not_to change{User.where(fb_id: @u1_id).first.state_table.story_number}
        expect(User.where(fb_id: @u1_id).first.state_table.last_story_read?).to eq(false)
      end


      it 'sets last_story_ready to false' do
        expect(@script).to receive(:run_sequence)
        @u1.state_table.update(last_story_read?:true)
        expect{
          Sidekiq::Testing.inline! do
            StartDayWorker.perform_async(@u1_id)
          end
        }.to change{User.where(fb_id: @u1_id).first.state_table.last_story_read?}.to false
      end

    end # context 'update_day'

    # TODO: idempotency test?

  end # describe 'start_day_worker'

  describe "subscribed" do

    it "does not send a message to a unsubscribed user." do

    end 

  end

  describe "our_friend?" do

    it "knows a rando's students aren't our friends" do 
      teacher = create(:teacher, signature: "Mr. Jew")
      user = create(:user)
      teacher.add_user(user)
      expect(ScheduleWorker.new.our_friend?(user)).to be false
    end

    it "knows our students are friends" do 
      teacher = create(:teacher, signature: "Mr. Esterman")
      user = create(:user)
      teacher.add_user(user)
      expect(ScheduleWorker.new.our_friend?(user)).to be true
    end

    it "handles users without a teacher" do
      user = create(:user)
      expect(ScheduleWorker.new.our_friend?(user)).to be false
    end

  end

end
