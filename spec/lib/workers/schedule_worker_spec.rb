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

		@time = Time.new(2016, 6, 24, 23, 0, 0, 0) # with 0 utc-offset
		@time_range = 10.minutes.to_i
		@interval = @time_range / 2.0								
		Timecop.freeze(@time)

		@s = ScheduleWorker.new

		@story_num = 2


		@on_time = User.create(:send_time => Time.now, fb_id: "12345")

		# 6:55:00 
		@just_early = User.create(:send_time => Time.now - @interval, fb_id: "23456")

		#  7:04:59pm
		@just_late = User.create(:send_time => Time.now + (@interval-1.minute) + 59.seconds, fb_id: "34567")

		# 6:54:59
		@early = User.create(:send_time => Time.now - (@interval+1.minute) + 59.seconds, fb_id: "45678")

		# 7:05
		@late = User.create(:send_time => Time.now + @interval, fb_id: "56789")

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


	context "timezone conversion function", :zone => true do
		before(:each) do
			@summer, @winter = @time, @time + 6.months
		end

		it "handles summer-summer and winter-winter cases (DST)" do
		# when the user enrolled in the summer and it's currently summer
			Timecop.freeze(@summer)
			user = User.create(:send_time => Time.now)
			expect(@s.adjust_tz(user)).to eq(user.send_time)
			# winter-winter case
			Timecop.freeze(@winter)
			user = User.create(:send_time => Time.now) # enrolled_on field is wintertime
			expect(@s.adjust_tz(user)).to eq(user.send_time)
		end

		it "subtracts an hour from the UTC clock when it's summer and the user enrolled during the winter" do
		# when the user enrolled in the winter and it's currently summer
			Timecop.freeze(@winter)
			user = User.create(:send_time => Time.now)
			Timecop.freeze(@summer)
			expect(@s.adjust_tz(user)).to eq(user.send_time - 1.hour)
		end

		it "adds an hour to the UTC clock when it's winter and the user enrolled during the summer" do 
		# when the user enrolled in the summer and it's currently winter
			Timecop.freeze(@summer)
			user = User.create(:send_time => @summer)
			Timecop.freeze(@winter)
			expect(@s.adjust_tz(user)).to eq(user.send_time + 1.hour)
		end
	end


	context "within_time_range function", :range => true do

		# it "returns true for users within the time interval at a given time" do 
		# 	expect(@s.within_time_range(@just_early, @interval, [Time.now.wday])).to be true
		# 	expect(@s.within_time_range(@just_late, @interval, [Time.now.wday])).to be true
		# end

		# it "returns false for users outside the time interval at a given time" do
		# 	expect(@s.within_time_range(@early, @interval, [Time.now.wday])).to be false
		# 	expect(@s.within_time_range(@late, @interval, [Time.now.wday])).to be false
		# end

		# it "does not send messages to a user twice" do
		# 	User.each {|u| u.destroy } # clean database

		# 	user = User.create(:send_time => Time.now + @interval - 1.second)
		# 	user.state_table.update(story_number: @story_num)
		# 	expect(@s.within_time_range(user, @interval, [Time.now.wday])).to be true
		# 	Timecop.freeze(Time.now + @time_range)
		# 	expect(@s.within_time_range(user, @interval, [Time.now.wday])).to be false			
		# end

	end

	context "filtering users", :filter => true do

		before(:each) do
			Timecop.freeze Time.new(2016, 6, 30, 23, 0, 0, 0)
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
				expect(StartDayWorker).to receive(:perform_async).with(user.fb_id).once
			end

			Sidekiq::Testing.inline! do
				sw.perform
			end
		end

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

			end

			before(:each) do
      	# users = User.all
				@users.each do |u|
					u.update(curriculum_version:666)
					u.state_table.update(story_number:2)
				end

			end

			describe 'day 1 behaviour', day1:true do

				# before each example, the user has already read day1!
				before(:each) do
					@users.each do |u|
						u.update(curriculum_version:666)
						u.state_table.update(story_number:1)
						u.state_table.update(last_story_read?:true)
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
				# day (901) #dang this is kinda dangerless (plz enforce =  @starting_story_num+1)
				sequence 'dummy_first' do |r|
					puts 'hey this worked'
				end
			end

			@script = Birdv::DSL::ScriptClient.scripts["day#{@starting_story_num+1}"]

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
				# 	Sidekiq::Testing.inline! do
				# 		StartDayWorker.perform_async(@u1_id)
				# 	end
				# }.to change{User.where(fb_id: @u1_id).first.state_table.story_number}.by 1

			end
			
			it 'does not increment day number when hasnt read last story', nosend:true do
				day = User.where(fb_id: @u1_id).first.state_table.story_number
				u1script = Birdv::DSL::ScriptClient.scripts["day#{day+1}"] 
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

		end

		# TODO: idempotency test?

	end

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
