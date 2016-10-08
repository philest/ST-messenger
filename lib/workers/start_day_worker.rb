require_relative '../helpers/fb'

class StartDayWorker
  include Sidekiq::Worker
  include Facebook::Messenger::Helpers

  sidekiq_options :retry => 3

  def read_yesterday_story?(user)
    # TODO: add a time-based condition?
    return true if user.state_table.story_number == 0

    if (user.platform == 'sms' or user.platform == 'feature') and user.state_table.subscribed?
      return true
    end

    return user.state_table.last_story_read?
  end

  def enroll_sms?(user)
    if (user.platform == 'sms' or user.platform == 'feature') and 
        user.state_table.subscribed? == false and
        user.state_table.story_number == 1 and
        user.fb_id.nil?
      # then I suppose we must not have enrolled in facebook yet...
      time_elapsed = Time.now - user.enrolled_on
      return (time_elapsed >= 8.days)
    end

    return false

  end

  def remind?(user)
    if read_yesterday_story?(user)
      false
    elsif (user.platform == 'sms' or user.platform == 'feature') and user.state_table.subscribed? == false
      time_elapsed = Time.now - user.enrolled_on
      if time_elapsed < 8.days
        return true
      end
      return false
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
      if user.state_table.subscribed? or user.state_table.story_number == 0
        user.state_table.update(story_number: n)
      end
    end

    return user.state_table.story_number
    # TODO: do error handling in a smart idempotent way (I mean, MAYBE)
  end

  def perform(recipient, platform='fb', sequence=:init)
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

    # problem - unsubscribed sms users don't get to the next part. 
    # so let's add a conditional. 
    # have to make sure the rest handles it properly....
    if not u.state_table.subscribed?
      # unless (u.platform == 'sms' or u.platform == 'feature') and u.state_table.story_number == 0 then
      story_number = u.state_table.story_number
      unless (story_number == 0) or (story_number == 1 and ['sms', 'feature'].include?(u.platform)) then
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

      elsif remind and (u.platform == 'sms' or u.platform == 'feature')
        # do something completely fucking different
        puts "we're in remind for sms! how did we even get here?? user: #{recipient}"
        # oh, nice! I set myself up for success ;) 
        reminder = Birdv::DSL::ScriptClient.scripts[platform]["remind"]
        reminder.run_sequence(recipient, :remind)

      elsif enroll_sms?(u) and (u.platform == 'sms' or u.platform == 'feature')
        # just fukin' enroll 'em!
        puts "We're just subscribing #{recipient} to SMS because they haven't replied at all to our messages! Gosh darn it!"
        u.state_table.update(subscribed?: true)
        puts "so, we proceed to send #{recipient} a story... FUCKERS"
        u.state_table.update(last_script_sent_time: Time.now.utc, num_reminders: 0)
        day_number = update_day(u, u.platform)
        # should be day2
        script = Birdv::DSL::ScriptClient.scripts[platform]["day#{day_number}"]
        script.run_sequence(recipient, sequence) 

      elsif not read_yesterday_story
        puts "this motherfucker #{recipient} hasn't read his last story. let's just leave him alone." 

      else # send a story button, the usual way, yippee!!!!!!!!!
        puts "proceeding to send #{recipient} a story... oh look, a cloud!"
        u.state_table.update(last_script_sent_time: Time.now.utc, num_reminders: 0)
        script.run_sequence(recipient, sequence) 
      end

    else
      #TODO: email?
      puts 'could not find scripts :('
      puts "likely, user #{recipient} has finished their curriculum"
      puts "#{recipient} is at story_number = #{day_number}"

      # if the person was on sms, go back 1 story because they shouldn't have updated their story_number
      if u.platform == 'sms' or u.platform == 'feature'
        current_no = u.state_table.story_number
        u.state_table.update(story_number: current_no - 1)
      end

    end
  end
end