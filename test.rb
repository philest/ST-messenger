# succeed in downloading the dev project's data in whatever available format

# https://mixpanel.com/api/2.0/segmentation?from_date=2017-02-8&to_date=2017-02-11&event=Viewed%20Page

# https://edbe89118bef0fa1f497d5db9c6b9ab5@mixpanel.com/api/2.0/segmentation?from_date=2016-02-11&to_date=2016-02-11&event=Phone Entered

# curl https://mixpanel.com/api/2.0/segmentation/ -u edbe89118bef0fa1f497d5db9c6b9ab5: -d from_date="2017-02-08" -d to_date="2017-02-11" -d event="Phone Entered"

# RAW DUMP:
# 
# curl 'https://data.mixpanel.com/api/2.0/export/?from_date=2017-02-08&to_date=2017-02-11&event=["Sync+Completely+Succeeded"]' -u edbe89118bef0fa1f497d5db9c6b9ab5:



# alright, I'm fine with this algorithm for now. let me get some food, mull it over,
# and if i can't think of anything better or wrong with it, let's implement!
# sort all entrance/exit events by timestamp (entrance/exits)
# iterate through list
# 
# if hit entrance on page X, store start in variable for that page
#   keep iterating
#   if you hit the exit on page X,
#     record entrance - exit timestamps
#     close the timestamp
#     
#   if you hit another entrance for a different page, just open interval for that page
#   
#   if you hit a second entrance for SAME page (X), reset the timestamp to that entrance
#     because something got fucked up along the way
#     as in, you shouldn't enter a page, then enter again! that is fucked

require 'httparty'
require 'active_support/time'


class ProcessMixpanel
  # separate class for all the processing
end



class Mixpanel
  include HTTParty
  base_uri 'https://data.mixpanel.com/api/2.0/export'

  @@default_range = {
    from_date: (Time.now-2.days),
    to_date: (Time.now-1.day)
  }

  def initialize(secret_key="edbe89118bef0fa1f497d5db9c6b9ab5")
    @auth = { username: secret_key, password: '' }
  end

  # add helper methods like converting dates to the proper format
  def events(options = @@default_range)
    # format dates
    options[:from_date] = format_date(options[:from_date]) if !options[:from_date].nil?
    options[:to_date] = format_date(options[:to_date]) if !options[:to_date].nil?

    res = self.class.get('', query: options, basic_auth: @auth)
    puts res

    if res.response.code.to_i == 200
      res.body.each_line.map {|line| JSON.parse line }
    end
  end

  def sort_by_timestamp(events)
    # get dates from events
    # sort that shit
  end

  def total_session_time(event1, event2)

  end


  private
  def format_date(date)
    date.strftime("%Y-%m-%d")
  end


end



# entering view
# {
#   event: "story page entered",
#   timestamp: Time.now,
#   properties: {
#     story: "Penguin",
#     page: 3
#   }
# }

# # exiting view
# {
#   event: "story page exited",
#   timestamp: Time.now + 1.minute, # or something
#   properties: {
#     story: "Penguin",
#     page: 3
#   }
# }



# 



# why would an entrance or exit fail to track? or handle 
# 
# two entering views before an exiting view
# 
# expect: e1, x1, e2, x2
# got:    e1, e2, x1, x2
# 
# e1, e2, x1, e3, x2, e3
# 
# 
# 
# we can possibly sort the events by entrance/exit and choose the closest ones
# 
# 
# 
# 
# 
# 
# 






# # The API also supports passing a time interval rather than an explicit date range
# data = client.request(
#   'events/properties',
#   event:    'splash features',
#   name:     'feature',
#   values:   '["uno", "dos"]',
#   type:     'unique',
#   unit:     'day',
#   interval: 7,
#   limit:    5
# )

# # Use the import API, which allows one to specify a time in the past, unlike the track API.
# # note that you need to include your api token in the data. More details at:
# # https://mixpanel.com/docs/api-documentation/importing-events-older-than-31-days
# data_to_import = {'event' => 'firstLogin', 'properties' => {'distinct_id' => guid, 'time' => time_as_integer_seconds_since_epoch, 'token' => api_token}}
# require 'base64' # co-located with the Base64 call below for clarity
# encoded_data = Base64.encode64(data_to_import.to_json)
# data = client.request('import', {:data => encoded_data, :api_key => api_key})
# # data == [1] # => true # you can only import one event at a time
# # 
# # 