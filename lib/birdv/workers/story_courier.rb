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
  	self.class.filter_users(DateTime.new(2016, 6, 24, 19), interval).each do |user|
  		StoryCourier.perform_async(user.name, user.fb_id, "some_title", 2)
  	end
 
  end

  private
  # time = current_time
  # interval = range of valid times
  def self.filter_users(time, interval)
	User.all.select do |user|
  		within_time_range(user.send_time, interval)
  	end

  end

  # need to make sure the send_time column is a Datetime type
  def self.within_time_range(time, interval)
    now = DateTime.now.seconds_since_midnight
    user_time = time.seconds_since_midnight
    if now >= user_time
    	now - user_time <= interval.minutes
    else
    	user_time - now <  interval.minutes
    end
  end

end







