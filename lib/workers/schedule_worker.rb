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
    return if u.nil?

    day_number =  update_day(u)
    puts "day#{day_number}"
		# double quotation
		script = Birdv::DSL::ScriptClient.scripts["day#{day_number}"]
    puts script.inspect
	  if !script.nil?
      script.run_sequence(recipient, :init) 
    else
      #TODO: email?
      puts 'could not find scripts :('
      puts "likely, user #{recipient} has finished their curriculum"
    end

	end

end

class ScheduleWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  attr_accessor :schedules

  def self.def_schedules
    return [
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
  end

  @schedules =  [
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

  # very inneficient, redo some day
  def get_schedule(story_number)
    if @sched
      sched = @sched
    else
      sched = self.class.def_schedules
    end
    last = []
    sched.each do |s|
      last = s[:days]
      if  s[:start_day] >= story_number
        return last
      end
    end
    return last
  end


  def perform(range=5.minutes.to_i)
		filter_users(Time.now, range).each do |user|

      puts user.fb_id
      puts user.state_table.story_number
      if user.fb_id
        StartDayWorker.perform_async(user.fb_id)
      end
		end
  end

  # time = current_time
  # range = range of valid times
  def filter_users(time, range)
    today_day = Time.now.utc
    alladem = User.all
    puts alladem.class 
    puts alladem.size

    begin
  	  filtered = alladem.select do |user|
    		# TODO - exception handling if the timezone isn't the correct name

        ut =  user.state_table.last_story_read_time
        # puts "RELEVANT: user_last_read #{Time.at(ut).to_date}, comp: #{Time.at(today_day).to_date}"
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
      puts "#{e.message}\nsomething went wrong, not filtering users\n#{e.backtrace}"
      filtered = []
    ensure
      puts "filtered = #{filtered.to_s}"
      return filtered
    end
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

  def is_us?(user)
    fname = user.first_name
    lname = user.last_name

    if    (fname == 'Aubrey')
      return true
    elsif (fname =="David" && lname == "McPeek")
      return true
    elsif (fname =="Phil"|| fname == "Philip" && lname == "Esterman")
      return true
    else
      return false
    end
  end

  # need to make sure the send_time column is a Datetime type
  def within_time_range(user, range, acceptable_days = [3])

  	# TODO: ensure that Time.now is in UTC time
  	# server timein UTC
    now                     = Time.now.utc # TODO: do I need to convert to tz?
		now_seconds 			      = now.seconds_since_midnight

		# DST-adjusted user time
		user_local              = adjust_user_tz(user)
		user_utc_seconds	      = user_local.utc.seconds_since_midnight
    # TODO: maybe move the following outside of the function so we don't have to 
    # compute some part over and over again:
		user_day 	      = get_local_day(now, user) # current day of the week for user according to server
            
    user_curric     = user.curriculum_version
    user_story_num  = user.state_table.story_number
 
    user_sched      = get_schedule(user_story_num)
    
    valid_for_user  = user_sched.include?(user_day)

    # this deals with the edge case of being on story 1:
    if (user_story_num == 1)
      lstrt = user.state_table.last_story_read_time
                             # TODO: double-check this logic...
      if !lstrt.nil?
      last_story_read_time = get_local_time(lstrt, user.timezone)
      
        days_elapsed = ((now - last_story_read_time) / (24 * 60 * 60)).to_i
        if days_elapsed < 7
          valid_for_user = false
        end
      end
    end
    

    # friends get it three days a week
    friend_days = [1,3,5]
    valid_for_friend = our_friend?(user) && friend_days.include?(user_day)

    # we get it all day erryday
    valid_for_mcesterwahl = is_us?(user)

    if (valid_for_user || valid_for_friend || valid_for_mcesterwahl) # just wednesday for now (see default arg)
      if now_seconds >= user_utc_seconds
				return (now_seconds - user_utc_seconds <= range)
			else
				return (user_utc_seconds - now_seconds <  range)
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

  # returns a time in the specified timezone
  def get_local_time(time, goal_timezone)
    tz = ActiveSupport::TimeZone.new(goal_timezone)

    # time that user enrolled, converted from UTC to local time
    return time.utc.in_time_zone(tz)
  end

  # TODO: fix specs
  def adjust_tz(user)
    adjust_user_tz(user)
  end

  def adjust_user_tz(user)

    #TODO comment
    utz = user.timezone
    if (utz.nil?)
      tz = "Eastern Time (US & Canada)" #TODO: add spec for default Eastern
    elsif (utz.is_a? String)
      if utz.empty?
        tz = "Eastern Time (US & Canada)"
      else
        tz = utz
      end
    else
      tz = utz
    end

    enroll_time = get_local_time(user.enrolled_on, tz)
    server_time = get_local_time(Time.now.utc, tz)
    
    # check if in daylight savings
    if enroll_time.dst? and not server_time.dst?
      send_time = user.send_time + 1.hour
    elsif not enroll_time.dst? and server_time.dst?
      send_time = user.send_time - 1.hour
    else
      send_time = user.send_time
    end

    return send_time
  end
end




