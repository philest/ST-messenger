class StartDayWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 30
   sidekiq_retry_in do |count|
    10
  end

  def perform(recipient, day_number)
  		# double quotation 
		Birdv::DSL::StoryTimeScript.scripts["day#{day_number}"].run_sequence(recipient, :init)
		# update the user day! TODO: make this a seperate job!
	end
end

class ScheduleWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(interval=5.minutes.to_i)
		filter_users(Time.now, interval).each do |user|
			StartDayWorker.perform_async(user.fb_id, user.story_number) if user.story_number > 1 #TODO: fix this stuff
		end
  end

  def adjust_tz(user)
  	user_tz = ActiveSupport::TimeZone.new(user.timezone)
  	tz_init = user.enrolled_on.in_time_zone(user_tz)
  	tz_current = Time.now.utc.in_time_zone(user_tz)

	if tz_init.dst? and not tz_current.dst?
		send_time = user.send_time + 1.hour
	elsif not tz_init.dst? and tz_current.dst?
		send_time = user.send_time - 1.hour
	else
		send_time = user.send_time
	end

	send_time
  end

  # time = current_time
  # interval = range of valid times
  def filter_users(time, interval)
	User.all.select do |user|
		# TODO - exception handling if the timezone isn't the correct name
		within_time_range(user, interval)
	end
  end

  # need to make sure the send_time column is a Datetime type
  def within_time_range(user, interval)
  	# TODO: ensure that Time.now is in UTC time
	now = Time.now.utc.seconds_since_midnight
	user_time = adjust_tz(user).utc.seconds_since_midnight
	if now >= user_time
		now - user_time <= interval
	else
		user_time - now <  interval
	end
  end
end




