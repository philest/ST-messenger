require_relative '../helpers/fb'

class StartDayWorker
  include Sidekiq::Worker
  include Facebook::Messenger::Helpers

  sidekiq_options :retry => 3

  def read_yesterday_story?(user)
    # TODO: add a time-based condition?
    return true if user.state_table.story_number == 0
    return true if user.platform == 'sms'
    return user.state_table.last_story_read?
  end

  def remind?(user)
    if read_yesterday_story?(user)
      false
    elsif user.platform == 'sms'
      false # we don't want reminders for sms, dawg.........
    else # fb user did NOT read yesterday's story
       # check to see if it's been over four days away...
        last_script_sent_time = user.state_table.last_script_sent_time
        if last_script_sent_time != nil then 
          days_elapsed = (Time.now.utc - last_script_sent_time) / 1.day
          # if more than four days have elapsed after the user did not read their last story, it's time to remind them
          return days_elapsed < 4 ? false : true
        else
          return false # don't remind them
        end
    end
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
      user.state_table.update(story_number: n)
    end

    return user.state_table.story_number
    # TODO: do error handling in a smart idempotent way (I mean, MAYBE)
  end

  def perform(recipient, platform='fb')
    case platform
    when 'fb'
      u = User.where(fb_id:recipient).first
    else
      u = User.where(phone:recipient).first
    end

    if u.nil? # user doesn't exist, they must be new
      puts "this user #{recipient} doesn't exist in StartDayWorker, creating them now..."
      register_user({'id'=>recipient})
      u = User.where(fb_id:recipient).first
    end

    if not u.state_table.subscribed?
      unless u.platform == 'sms' and u.state_table.story_number == 0 then
        puts "WE'RE FUCKING UNSUBSCRIBED DAWG - #{recipient}"
        return
        # otherwise, we haven't even sent out our first story to this poor sms user
        # and we ought to, for them, y'know?
      end
    end

    read_yesterday_story = read_yesterday_story?(u)
    remind = remind?(u)

    # ok, now finally updating day... be careful here, because we change some state_table values
    # like last_story_read and story_number
    day_number =  update_day(u, platform)

		# double quotation
		script = Birdv::DSL::ScriptClient.scripts[platform]["day#{day_number}"]

	  if !script.nil?

      if remind and u.platform == 'fb'

        reminder = Birdv::DSL::ScriptClient.scripts[platform]["remind"]

        last_reminded_time = u.state_table.last_reminded_time
        num_reminders = u.state_table.num_reminders

        puts "state_table = #{u.state_table.inspect}"

        # we've never sent a reminder before, so send one now
        if last_reminded_time.nil? || num_reminders == 0
          puts "sending a reminder to #{recipient}"
          # send a regular reminder
          u.state_table.update(last_reminded_time: Time.now.utc, num_reminders: 1)
          reminder.run_sequence(recipient, :remind)
          # send the button again, but don't update last_script_sent_time
          script.run_sequence(recipient, :storybutton)
        else # we have send a reminder, so either unsubscribe or do nothing
          puts "we've sent a reminder before, so check if we need to unsubscribe..."
          # this should not be nil because we just used last_script_sent_time with remind?(u),
          # which only returns true if the field is not nil
          last_script_sent_time = u.state_table.last_script_sent_time
          # our last reminder was sent more recently than the last story that was sent
          unsubscribe = last_reminded_time > last_script_sent_time
          # the last story that was sent (and not read) was sent over 10 days ago
          unsubscribe &&= (Time.now.utc - last_script_sent_time) > 10.days

          puts "unsubscribe = #{unsubscribe}"

          if unsubscribe
            # send the unsubscribe message
            u.state_table.update(subscribed?: false)
            reminder.run_sequence(recipient, :unsubscribe)
          end
          # otherwise, do nothing
        end

      elsif remind and u.platform == 'sms'
        # do something completely fucking different
        puts "we're in remind for sms! how did we even get here?? user: #{recipient}"

      elsif not read_yesterday_story
        puts "this motherfucker #{recipient} hasn't read his last story. let's just leave him alone." 

      else # send a story button, the usual way, yippee!!!!!!!!!
        puts "proceeding to send #{recipient} a story..."
        u.state_table.update(last_script_sent_time: Time.now.utc, num_reminders: 0)
        script.run_sequence(recipient, :init) 
      end

    else
      #TODO: email?
      puts 'could not find scripts :('
      puts "likely, user #{recipient} has finished their curriculum"
      puts "#{recipient} is at story_number = #{day_number}"

      # if the person was on sms, go back 1 story because they shouldn't have updated their story_number
      if u.platform == 'sms'
        current_no = u.state_table.story_number
        u.state_table.update(story_number: current_no - 1)
      end

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


  # story_number = 1  [4]
  #              = 2  [1, 4]
  #              = 3  [1, 4]
  #              = 4  [1, 2, 4]
  #              = 5  [1, 2, 4]
  #              = 6  [1, 2, 4]
  #              = 10 [1, 2, 4]
 
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

    filtered = filter_users(Time.now, range)
    fb       = filtered.select { |u| u.platform == 'fb' }
    sms      = filtered.select { |u| u.platform == 'sms' }

    for user in fb
      puts "fb_id = #{user.fb_id}, story_number = #{user.state_table.story_number}" 
      StartDayWorker.perform_async(user.fb_id, platform='fb') if user.fb_id
    end

    if sms.size == 0 then 
      return 
    end

    # split them up into chunks of size = 3
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
    # group_delay = 30.seconds
    # individual_delay = 5.seconds

    group_delay = group_time / num_groups
    individual_delay = individual_time.to_f / sms.size # where sms.size is the number of individuals
          puts "group_delay = #{group_delay}"
    puts "individual_delay = #{individual_delay}"

    group_index = 0
    individual_index = 0

    sms.size.times do |i|

      if i % group_size == 0 and i != 0
        group_index += 1 # increment
        individual_index = 0 # reset
      end

      puts "individual_index = #{individual_index}"
      puts "group_index = #{group_index}"


      delay = (group_delay * group_index) + (individual_delay * individual_index)
      puts "delay = #{delay.inspect}"
      user = sms[i]
      StartDayWorker.perform_in(delay.seconds, user.phone, platform='sms') if user.phone

      individual_index += 1

    end

		# filter_users(Time.now, range).each do |user|
  #     case user.platform
  #     when 'fb'
  #       puts "fb_id = #{user.fb_id}, story_number = #{user.state_table.story_number}" 
  #       StartDayWorker.perform_async(user.fb_id, platform='fb') if user.fb_id
  #     when 'sms'
  #       puts "phone = #{user.phone}, story_number = #{user.state_table.story_number}"
  #       StartDayWorker.perform_async(user.phone, platform='sms') if user.phone
  #     end
		# end

  end

  # time = current_time
  # range = range of valid times
  def filter_users(time, range)
    today_day = Time.now.utc
  	filtered = User.all.select do |user|
      ut =  user.state_table.last_story_read_time
      if ut.nil?
        last_story_read_ok = true
      elsif !(Time.at(ut).to_date === Time.at(today_day).to_date)
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
    return time + tz_offset
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




