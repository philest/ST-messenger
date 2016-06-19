require 'active_support/time'

class StoryCourier
  include Sidekiq::Worker
  def perform(name, fb_id, title, length)
	base_url = "https://s3.amazonaws.com/st-messenger/old_stories/"
	story_url = base_url + title
	length.times do |page|
	  page_url = "#{story_url}/#{title}#{page+1}.jpg" 
	  FB.send_pic(fb_id, page_url)
	end

	# TODO, add completed to a DONE pile. Then we can increment story num.
	# But for now,
	# DB[:users].where(:name => name).update(:story_number=>Sequel.expr(:story_number)+1)
  end
end

class ScheduleWorker
  include Sidekiq::Worker
  def perform
	interval = 5
	filter_users(Time.now, interval).each do |user|
		StoryCourier.perform_async(user.name, user.fb_id, "some_title", 2)
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
		user_tz = ActiveSupport::TimeZone.new(user.timezone)
		# figure out the date that this user enrolled. the send_time was adjusted based on DST
		# readjust depending on whether it's the summer or winter
		# 
		# maybe we should have a periodic job that runs every day... it updates the users'
		# send_times to reflect their local send_time when they just started out, by DST. 
		# can we make a sequel default field dependent on another field, like :enrolled_on ? 
		


		# # handle Daylight Savings Time
		# if user.enrolled_on.dst? and not Time.now.utc.in_time_zone(user_tz).dst?
		# 	send_time = user.send_time + 1.hour
		# elsif not user.enrolled_on.dst? and Time.now.utc.in_time_zone(user_tz).dst?
		# 	send_time = user.send_time - 1.hour
		# else
		# 	send_time = user.send_time
		# end

		within_time_range(send_time, interval)
	end
  end

  # need to make sure the send_time column is a Datetime type
  def within_time_range(user, interval)
  	# TODO: ensure that Time.now is in UTC time
	now = Time.now.utc.seconds_since_midnight
	user_time = adjust_tz(user).utc.seconds_since_midnight
	if now >= user_time
		now - user_time <= interval.minutes
	else
		user_time - now <  interval.minutes
	end
  end

end









