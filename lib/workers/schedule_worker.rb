class StartDayWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3
  #  sidekiq_retry_in do |count|
  #   10
  # end

  def read_yesterday_story?(user)
    # TODO: add a time-based condition?
    return user.state_table.last_story_read?
  end
  
  def update_day(user)

    if read_yesterday_story?(user)
      n = user.state_table.story_number + 1
      user.state_table.update(story_number: n, 
                              last_story_read?: false)
    end
    return user.state_table.story_number
    # TODO: do error handling in a smart idempotent way
  end

  def perform(recipient)
      u = User.where(fb_id:recipient).first

      day_number =  update_day(u)
      puts "day#{day_number}"
  		# double quotation
  		script = Birdv::DSL::ScriptClient.scripts["day#{day_number}"]
      puts script
		  if !script.nil?
        script.run_sequence(recipient, :init) 
      else
        #TODO: email?
        puts 'could not find scripts :('
      end

	end
end

class ScheduleWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(range=5.minutes.to_i)
		filter_users(Time.now, range).each do |user|
			StartDayWorker.perform_async(user.fb_id) if user.state_table.story_number > 1 #TODO: fix this stuff
		end
  end

  # time = current_time
  # range = range of valid times
  def filter_users(time, range)
    today_day = Time.now.utc
  	filtered = User.all.select do |user|
  		# TODO - exception handling if the timezone isn't the correct name

      ut =  user.state_table.last_story_read_time

      puts "THE COMP #{Time.at(today_day)} THE USER #{ut}, #{ut.class}, #{ut.nil?}"
      puts ""

      if !ut
        last_story_read_ok = true
      elsif !(Time.at(ut).to_date === Time.at(today_day).to_date)
        last_story_read_ok = true 
      else    
        last_story_read_ok = false
      end

      # ensure is within_time_range and that last story read wasn't today!
  		within_time_range(user, range) && last_story_read_ok
  	end
  rescue => e
    p e.message " something went wrong, not filtering users"
    filtered = []
  ensure
    puts "filtered = #{filtered.to_s}"
    return filtered
  end

  # is this our student? 
  def our_friend?(user)
    if user.teacher.nil? 
      return false 
    end 

    match = user.teacher.signature.match(/esterman/i) || 
    user.teacher.signature.match(/wahl/i) ||
    user.teacher.signature.match(/mcpeek/i) ||
    user.teacher.signature.match(/mcesterwahl/i)

    if match.nil? 
      return false 
    else 
      return true 
    end
  end

  # need to make sure the send_time column is a Datetime type
  def within_time_range(user, range, acceptable_days = [3])
  	# TODO: ensure that Time.now is in UTC time

  	# server timein UTC
		now 			= Time.now.utc.seconds_since_midnight

		# DST-adjusted user time
		user_local = adjust_tz(user)
		user_utc	 = user_local.utc.seconds_since_midnight
		user_day 	 = get_local_day(Time.now, user)

    valid_for_user = acceptable_days.include?(user_day)

    #friends get it three days a week
    friend_days = [1,3,5]
    valid_for_friend = our_friend?(user) && friend_days.include?(user_day)

    if (valid_for_user || valid_for_friend) # just wednesday for now (see default arg)
			if now >= user_utc
				return now - user_utc <= range
			else
				return user_utc - now <  range
			end
		end
    return false
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




