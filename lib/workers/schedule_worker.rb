class StartDayWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3
  #  sidekiq_retry_in do |count|
  #   10
  # end

  # Why does this function exist? Wasteful! Stupid!
  def read_yesterday_story?(user)
    # TODO: add a time-based condition?
    return user.state_table.last_story_read?
  end
  
  def update_day(user, platform)
    n = user.state_table.story_number + 1
    case platform
    when 'fb'
      if read_yesterday_story?(user)
        user.state_table.update(story_number: n, 
                                last_story_read?: false)
      end
    else # platform == 'mms' or 'sms'
      # Update. Since there are no buttons, we just assume peeps have read their story. 
      # An alternative is we ask that someone reply to an initial text before we send them a story.
      # Talk to the team about this option. 
      user.state_table.update(story_number: n)
    end

    return user.state_table.story_number
    # TODO: do error handling in a smart idempotent way
  end

  def perform(recipient, platform='fb')
    case platform
    when 'fb'
      u = User.where(fb_id:recipient).first
    else
      u = User.where(phone:recipient).first
    end
    
    return if u.nil?

    day_number =  update_day(u, platform)
    puts "day#{day_number}"
		# double quotation
		script = Birdv::DSL::ScriptClient.scripts[platform]["day#{day_number}"]
    puts script.inspect
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

        case user.platform
        when 'fb'
          StartDayWorker.perform_async(user.fb_id, platform='fb') if user.fb_id
        when 'sms'
          StartDayWorker.perform_async(user.phone, platform='sms') if user.phone
        end

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
        # if the last story wasn't sent today (has to be at least since yesterday)
        last_story_read_ok = true 
      else    
        last_story_read_ok = false
      end

      # REMOVE THIS LINE, THIS IS JUST FOR TESTING!!!!!!
      last_story_read_ok = true

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
    puts "user name = #{user.first_name}"
    puts "user send_time = #{user.send_time}"

  	# server timein UTC
		now 			= Time.now.utc.seconds_since_midnight
    puts "seconds since midnight now = #{now}"

		# DST-adjusted user time
		user_local = adjust_tz(user)
		user_utc	 = user_local.utc.seconds_since_midnight
    puts "user's seconds since midnight = #{user_utc}"
    puts "now - user_utc = #{(Time.now.utc - user_local.utc)/60} minutes, #{(Time.now.utc - user_local.utc)/3600} hours"
		user_day 	 = get_local_day(Time.now.utc, user)

    valid_for_user = acceptable_days.include?(user_day)

    #friends get it three days a week
    friend_days = [1,3,5]
    valid_for_friend = our_friend?(user) && friend_days.include?(user_day)

    if (valid_for_user || valid_for_friend) # just wednesday for now (see default arg)
      puts "valid for user or valid for friend"
			if now >= user_utc
        puts "now >= user_utc is #{now - user_utc <= range}"

				return now - user_utc <= range
			else
        puts "now < user_utc is #{user_utc - now <  range}"
				return user_utc - now <  range
			end
		end
    puts "not valid, returning false"
    return false
  end

  # returns the day of the week,
  # e.g. Monday => 1, Saturday => 6
  def get_local_day(server_time, user)
    return (server_time.utc + user.tz_offset.hours).wday
  	# user_tz = ActiveSupport::TimeZone.new(user.timezone)
  	# return server_time.utc.in_time_zone(user_tz).wday
  end

  # returns the user's DST-adjusted local time
  def adjust_tz(user)
  	# # timezone object in User's timezone
  	# user_tz = ActiveSupport::TimeZone.new(user.timezone)

  	# # time that user enrolled, converted from UTC to local time
  	# tz_init = user.enrolled_on.utc.in_time_zone(user_tz)

  	# # server time, converted to local time zone
  	# tz_current = Time.now.utc.in_time_zone(user_tz)

    # 23:00 - 4 = 19:00 = 7pm

    est_offset = 4 # the tz_offset of EST, the default timezone

    est_adjust = (user.tz_offset + est_offset).hours
    puts "user tz_offset = #{user.tz_offset}"

    adjusted_send_time = user.send_time - est_adjust


    puts "before, user.send_time = #{user.send_time}"
    puts "after, user.send_time = #{adjusted_send_time}"

    return adjusted_send_time

  end

end




