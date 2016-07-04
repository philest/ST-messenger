class StartDayWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3
  #  sidekiq_retry_in do |count|
  #   10
  # end

  def perform(recipient, day_number)
  		# double quotation 
  		script = Birdv::DSL::StoryTimeScript.scripts["day#{day_number}"]
		  if not script.nil?
        script.run_sequence(recipient, :init) 
      end
		# update the user day! TODO: make this a seperate job!
	end
end

class ScheduleWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(range=5.minutes.to_i)
		filter_users(Time.now, range).each do |user|
			StartDayWorker.perform_async(user.fb_id, user.story_number) if user.story_number > 1 #TODO: fix this stuff
		end
  end

  # time = current_time
  # range = range of valid times
  def filter_users(time, range)
  	filtered = User.all.select do |user|
  		# TODO - exception handling if the timezone isn't the correct name
  		within_time_range(user, range)
  	end
  rescue => e
    p e.message " something went wrong, not filtering users"
    filtered = []
  ensure
    puts "filtered = #{filtered.to_s}"
    return filtered
  end

    # need to make sure the send_time column is a Datetime type
  def within_time_range(user, range)
  	# TODO: ensure that Time.now is in UTC time

  	# server timein UTC
		now 			= Time.now.utc.seconds_since_midnight

		# DST-adjusted user time
		user_local = adjust_tz(user)
		user_utc	 = user_local.utc.seconds_since_midnight
		user_day 	 = get_local_day(Time.now, user)
		if (user_day==1||user_day==3||user_day==5)
			if now >= user_utc
				now - user_utc <= range
			else
				user_utc - now <  range
			end
		end
  end

  # returns the day of the week,
  # e.g. Monday => 1, Saturday => 6
  def get_local_day(server_time, user)
  	user_tz = ActiveSupport::TimeZone.new(user.timezone)
  	return server_time.utc.in_time_zone(user_tz).wday
  end

  # returns the user's DST-adjusted local time
  def adjust_tz(user)
  	# timezone object in User's timezone
  	user_tz = ActiveSupport::TimeZone.new(user.timezone)

  	# time that user enrolled, converted from UTC to local time
  	tz_init = user.enrolled_on.utc.in_time_zone(user_tz)

  	# server time, converted to local time zone
  	tz_current = Time.now.utc.in_time_zone(user_tz)

  	# check if in daylight savings
		if tz_init.dst? and not tz_current.dst?
			send_time = user.send_time + 1.hour
		elsif not tz_init.dst? and tz_current.dst?
			send_time = user.send_time - 1.hour
		else
			send_time = user.send_time
		end

		send_time
  end

end




