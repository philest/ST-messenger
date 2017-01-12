require_relative '../helpers/fb'
require_relative 'start_day_worker'

class ScheduleWorker
  include Sidekiq::Worker
  
  # how many times should this retry??
  sidekiq_options :retry => 3
  # sidekiq_options :retry => false

  attr_accessor :schedules

  def self.def_schedules
    return [
      { 
        start_day: 2,
        days: [4]
      },
      {
        start_day: 100,
        days: [2,4]
      },
      {
        start_day: 150,
        days: [2,3,4]
      }
    ]
  end

  @schedules =  [
    { 
      start_day: 2,
      days: [4]
    },
    {
      start_day: 100,
      days: [2,4]
    },
    {
      start_day: 150,
      days: [2,3,4]
    }
  ]


  # story_number = 1  [4]
  #              = 2  [1, 4]
  #              = 3  [1, 4]
  #              = 4  [1, 2, 4]
  #              = 5  [1, 2, 4]
  #              = 6  [1, 2, 4]
  #              = 10 [1, 2, 4]
 
  # very inneficient, redo some day
  def get_schedule(story_number)
    if @schedules
      sched = @schedules
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

    filtered = filter_users(Time.now, range)
    fb       = filtered.select { |u| u.platform == 'fb' }
    sms      = filtered.select { |u| u.platform == 'sms' or u.platform == 'feature' }
    app      = filtered.select { |u| u.platform == 'app' or u.platform == 'android' or u.platform == 'ios' }
    puts "app users = #{app.inspect}"

    # schedule for app
    app.each do |user|
      StartDayWorker.perform_async(user.fcm_token, platform='app') if user.fcm_token
    end

    # for user in fb
    #   puts "fb_id = #{user.fb_id}, story_number = #{user.state_table.story_number}" 
    #   StartDayWorker.perform_async(user.fb_id, platform='fb') if user.fb_id
    # end

    # first fb
    if fb.size > 0

      if fb.size < 10
        total_time = fb.size.minutes
      else
        total_time = 10.minutes
      end 

      ind_delay = total_time / fb.size

      fb.size.times do |i|
        delay = (ind_delay * i)
        puts "delay for fb user = #{delay} seconds, #{delay/1.minute.to_f} minutes"
        user = fb[i]
        StartDayWorker.perform_in(delay.seconds, user.fb_id, platform='fb') if user.fb_id
      end
      
    end


    if sms.size == 0 then 
      return 
    end

    # split them up into chunks of size = 3 (or 1?)
    # each of those are a second or two apart
    #   but each chunk is thirty seconds apart from the neighboring chunks
    group_size = 1.0
    num_groups = (sms.size / group_size).ceil
    puts "num_groups = #{num_groups}"

    # upperbound our time to 1 hour so we don't go overboard with waiting
    total_time = 1.hour

    if sms.size < 60 # if there are under 60 people, give them a minute each
      group_time = sms.size.minutes
    else
      group_time = total_time
    end

    individual_time = total_time - group_time

    # for each chunk, run StartDayWorker a few seconds apart. 
    group_delay = group_time / num_groups
    individual_delay = individual_time.to_f / sms.size # where sms.size is the number of individuals

    group_index = 0
    individual_index = 0

    sms.size.times do |i|

      if i % group_size == 0 and i != 0
        group_index += 1 # increment
        individual_index = 0 # reset
      end

      delay = (group_delay * group_index) + (individual_delay * individual_index)
      puts "delay = #{delay.inspect}"
      user = sms[i]
      StartDayWorker.perform_in(delay.seconds, user.phone, platform=user.platform) if user.phone

      individual_index += 1

    end

  end

  # time = current_time
  # range = range of valid times
  def filter_users(time, range)
    today_day = Time.now.utc
  	filtered = User.all.select do |user|
      ut =  user.state_table.last_story_read_time
      lsst = user.state_table.last_script_sent_time
      if ut.nil? or lsst.nil?
        last_story_read_ok = true
      elsif Time.at(ut).to_date != Time.at(today_day).to_date && 
            Time.at(lsst).to_date != Time.at(today_day).to_date

        # if the last story wasn't sent today (has to be at least since yesterday)
        last_story_read_ok = true 
      else    
        last_story_read_ok = false
      end

      # ensure is within_time_range and that last story read wasn't today!
  		last_story_read_ok && within_time_range(user, range)
  	end
  rescue => e
    p e.message + "... something went wrong, not filtering users"
    filtered = []
  ensure
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
  def within_time_range(user, range, acceptable_days = [])

  	# TODO: ensure that Time.now is in UTC time
  	# server timein UTC
		# now 			= Time.now.utc.seconds_since_midnight
    now       = Time.now.utc
    # DST-adjusted user time
    user_sendtime_local = adjust_tz(user)
    user_sendtime_utc   = user_sendtime_local.utc
		user_day 	 = get_local_day(Time.now.utc, user)
    user_story_num  = user.state_table.story_number
    user_sched      = get_schedule(user_story_num)
    valid_for_user  = user_sched.include?(user_day) || acceptable_days.include?(user_day) || user_story_num == 0
    # # # this deals with the edge case of being on story 1:
    # if (user_story_num == 1)
    #   lstrt = user.state_table.last_story_read_time
    #   # TODO: double-check this logic...
    #   if !lstrt.nil?
    #     last_story_read_time = get_local_time(lstrt, user.tz_offset)
      
    #     days_elapsed = ((now - last_story_read_time) / (24 * 60 * 60)).to_i
    #     if days_elapsed < 7
    #       valid_for_user = false
    #     end
    #   end
    # end

    # remove the friend thing...
    # friend_days = []
    # valid_for_friend = our_friend?(user) && friend_days.include?(user_day)
    # we get it all day erryday
    valid_for_mcesterwahl = is_us?(user)
    if (valid_for_user || valid_for_mcesterwahl) # just wednesday for now (see default arg)
			if now >= user_sendtime_utc
				return now - user_sendtime_utc <= range
			else
				return user_sendtime_utc - now < range
			end
		end
    # else, not valid for user, friend, or mcesterwahl
    return false
  end

  # returns the day of the week,
  # e.g. Monday => 1, Saturday => 6
  def get_local_day(server_time, user)
    return (server_time.utc + user.tz_offset.hours).wday
  end

  # returns a time in the specified timezone offset
  def get_local_time(time, tz_offset)
    return time + tz_offset.hours
  end

  # returns the user's DST-adjusted local time
  def adjust_tz(user)
    est_offset = 4 # the tz_offset of EST, the default timezone
    est_adjust = (user.tz_offset + est_offset).hours
    # in Pacific time, this would be adding a positive number of hours
    adjusted_send_time = user.send_time - est_adjust
    ast = adjusted_send_time
    new_send_time = Time.new(Time.now.utc.year, Time.now.utc.month, Time.now.utc.day, ast.hour, ast.min, ast.sec, ast.utc_offset)
    return new_send_time
  end
end




