# require_relative('bin/production.rb')
require 'dotenv'
Dotenv.load
require 'gruff'
require 'fileutils'
require 'twilio-ruby'

class Stats
  attr_accessor :name, :users, :start_date, :dir, :time_interval

  def initialize(name, user_query, start_date, dir="", time_interval=1.day)
    @name = name
    @users = user_query
    @start_date = start_date
    @dir = dir
    @time_interval = time_interval
  end


  def labels(start, end_date, interval)
    date = start
    axis = {}
    index = 0
    while date < end_date
      formatted_date = "#{date.month}/#{date.day}"
      axis[index] = formatted_date
      date += interval
      index += 1
    end
    return axis
  end

  def get_conversation(phone)
    client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']
    messages = client.account.messages.list({to: phone})
    received = client.account.messages.list({from: phone})
    msgs_sent = []
    msgs_received = []

    while messages.size > 0
      msgs_sent += messages
      messages = messages.next_page
    end

    while received.size > 0
      msgs_received += received
      received = received.next_page
    end

    conversation = msgs_sent + msgs_received
    conversation.sort_by! {|c| DateTime.parse(c.date_updated) }

    # do something with media....
    # msgs_sent.each do |m|
    #   begin
    #     m.media.list.each do |img| 
    #       puts img.content_type
    #     end
    #   rescue => e
    #     puts e
    #     next
    #   end
    # end

    return {
      sent: msgs_sent,
      received: msgs_received,
      convo: conversation
    }
  end

  def text_replies
    phone_numbers = users.map(:phone)

    client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']

    user_convos = {}

    phone_numbers.each do |phone|
      user_convos[phone] = get_conversation(phone)
      puts phone
    end

    return user_convos
  end


  def draw_graph(graph, url)
    dirname = "graphs/#{dir}"
    dirname = "/Users/jdmcpeek/Dropbox/StoryTime Materials/Data/#{dir}"
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    # base_url = "graphs/#{dir}"

    graph.theme = {
      :colors => [
        '#EFAA43',  # orange
        '#8A6EAF',  # purple
        '#FDD84E',  # yellow
        '#D1695E',  # red
        '#72AE6E',  # green
        '#6886B4',  # blue
        'white'
      ],
      :marker_color => 'orange',
      :font_color => 'black',
      :background_colors => %w(white white)
    }

    graph.font = File.expand_path("/Users/jdmcpeek/Library/Fonts/AvenirLTStd-Medium.otf")

    graph.write("#{dirname}/#{url}")
  end


  def persistence(interval=1.week, our_users=users)
    g = Gruff::Bar.new
    g.title = "Persistence"

    our_users = our_users.where(platform: 'fb').where{enrolled_on > Time.now - 5.weeks}

    max_time = our_users.min(:enrolled_on)
    puts "max_time = #{max_time}"
    num_weeks = ((Time.now - max_time) / 1.week).floor


    g.labels = 1.upto(num_weeks).inject({}) do |result, element|
      result[element] = "w#{element}"
      result
    end


    puts "num_weeks = #{num_weeks}"
    data = 1.upto(num_weeks).map do |week_n|
      puts "week_n = #{week_n}"
      # the people who've been around for at least n weeks
      enrolled_users = our_users.all.select do |u|
        Time.now - u.enrolled_on >= week_n.weeks
      end

      # of those, the people who unsubscribed during that time ()
      unsubscribed = enrolled_users.select do |u| 
        dropoff = u.state_table.subscribed? == false
        dropoff &&= (u.state_table.updated_at - u.enrolled_on) <= week_n.weeks
        # dropoff &&= (u.state_table.updated_at - u.enrolled_on) >= (week_n - 1).weeks
        dropoff
      end

      unsubscribed.each do |u|
        how_many = (u.state_table.updated_at - u.enrolled_on) / 1.week
        enr = (Time.now - u.enrolled_on) / 1.week
        puts "#{u.first_name} #{u.last_name} unsubscribed after #{how_many} weeks, enrolled for #{enr} weeks"
      end

      puts "enrolled_users = #{enrolled_users.size}, dropoffs = #{unsubscribed.size}\n\n"

      (enrolled_users.size - unsubscribed.size.to_f) / enrolled_users.size.to_f

      # what do we need to know?
      # for each week that people are on the program,
      # take a week. week x.
      # get everyone in the system who has been around for that much time. that's enrolled_users
      # of those, some have been around for longer than week_n. so we have to be sure that we're
      #   getting their state at that particular week. how do we do that?
      #   check to see whoever's unsubscribed. that's the upper bound.
      #   then check the timestamp for when the state_table was last updated.
      #   if it was updated before that week in their enrollment history, then they were
      #     unenrolled on that week. (on the week)
      #   if it was updated after, then they weren't.
      # get the number of people who are not unsubscribed by then
    end
    puts data

    g.data "percent of parents who read with StoryTime 3 times/week", data

    g.minimum_value = 0

    draw_graph(g, 'persistence.png')

  end

  def dropout_rates(interval=1.week, our_users=users)
    fb_users ||= our_users.where(platform: 'fb')
    dropouts = fb_users.filter(state_table: StateTable.where(subscribed?: false)
                                                      .where{story_number > 1})
    # we're going every month
    today = Time.now + 1.week
    date = dropouts.min(:enrolled_on)
    # the graph
    g = Gruff::Line.new
    g.title = "Dropouts"
    g.labels = labels(date, today, interval)
    num_dropouts = []
    the_dropouts = []
    while date < today
      dropouts_this_week = dropouts.where(state_table: StateTable.where{updated_at >= date}
                                                                  .where{updated_at < date + interval}).all
      num_dropouts << dropouts_this_week.size
      the_dropouts << dropouts_this_week
      date += interval
    end
    g.data "Number of Dropouts", num_dropouts
    # g.write('graphs/number_of_dropouts.png')

    draw_graph(g, "number_of_dropouts.png")
    return the_dropouts
  end

  # 11. of all people who drop out, what is the average week (plot week-by-week) that they do
  def dropouts(interval=1.month, our_users=users)
    fb_users ||= our_users.where(platform: 'fb')
    dropouts = fb_users.filter(state_table: StateTable.where(subscribed?: false)
                                                      .where{story_number > 1})

    if dropouts.count == 0
      puts "THERE ARE NO DROPOUTS, YAY!"
      return 
    end

    # we're going every month
    today = Time.now + 1.week

    date_index = 0
    date = dropouts.min(:enrolled_on)
    interval = 2.weeks

    g = Gruff::Bar.new
    g.title = "Average monthly dropouts"
    g.labels = labels(date, today, interval)
    average_dropout_week = []
    average_story_number = []

    all_dropouts = dropout_rates(interval, our_users)

    all_dropouts.each do |dropouts_this_month|
      dropout_weeks = []
      story_nos     = []

      dropouts_this_month.each do |u|
        st = u.state_table
        dropout_weeks << (st.updated_at - u.enrolled_on)/1.week
        story_nos << st.story_number
      end

      avg_dw = (dropout_weeks.inject(:+).to_f / dropout_weeks.size)
      avg_sn = (story_nos.inject(:+).to_f / story_nos.size)

      average_dropout_week << ((dropout_weeks.size > 0) ? avg_dw : 0)
      average_story_number << ((story_nos.size > 0) ? avg_sn : 0)

    end


    g.data "Average Dropout Week", average_dropout_week
    g.data "Average Dropout Story", average_story_number

    # g.write("graphs/average_dropouts3.png")


    draw_graph(g, "average_dropouts.png")

    # ok, so we're going to have to extrapolate dropout week from story_number
    # or maybe we can take it from updated_at... if that's the last thing they did
    #   was get the unsubscribe message....
    #   
    # maybe we can just skip the first three weeks because they're all getting stories automatically...
    # 
    # 

  end

  def locale
    num_english = users.where(locale: 'en').count
    num_spanish = users.where(locale: 'es').count
    puts "English: #{num_english} - Spanish: #{num_spanish}"

    g = Gruff::Pie.new
    g.title = "#{name} parents on StoryTime: language"
    g.data(:English, num_english)
    g.data(:Spanish, num_spanish)
    draw_graph(g, "language.png")
  end

  def platform
    num_fb      = users.where(platform: 'fb').count
    num_sms     = users.where(platform: 'sms').count
    num_feature = users.where(platform: 'feature').count
    g = Gruff::Pie.new
    g.title = "#{name} parents on StoryTime: the tech they use"
    g.data('Facebook Messenger', num_fb)
    g.data('Text and picture messages', num_sms + num_feature)
    # g.data(:Feature, num_feature)
    draw_graph(g, "platforms.png")
  end


  def enrollment
    g = Gruff::Line.new
    g.title = "Parents enrolled on StoryTime"

    today = Time.now + 1.week
    enrollment_growth = []
    start = start_date
    date = users.where{enrolled_on >= start}.min(:enrolled_on)
    start = date
    # prev_week = 1
    while date < today
      # enrollment for everyone
      enrollment = users.where{enrolled_on < date}.count
      enrollment_growth << enrollment
      date += 1.week
    end
    g.labels = labels(start, today, 1.week)
    g.data "#{name} parents", enrollment_growth
    draw_graph(g, "enrollment.png")
    return enrollment_growth
  end

  def growth
    today = Time.now + 1.week

    enrollment_growth = []

    percent = Gruff::Line.new
    percent.title = "\% growth over time"
    percent_growth = []

    r = Gruff::Line.new
    r.title = "Growth rate (users/week)"
    growth_rate = []

    start = start_date
    date = users.where{enrolled_on >= start}.min(:enrolled_on)
    start = date

    # seed with the users who enrolled in the first time_interval
    interval = time_interval
    prev_week = users.where{(enrolled_on >= date) && (enrolled_on < (date + interval))}.count

    # begin after those initial users have already gone
    date += time_interval

    # prev_week = 1
    while date < today
      puts "new date = #{date}"
      # enrollment for everyone
      enrollment = users.where{enrolled_on <= date}.count
      enrollment_growth << enrollment
      percent_growth << ((enrollment - prev_week) / prev_week.to_f ) * 100

      growth_rate << (enrollment - prev_week)

      date += 1.week
      prev_week = enrollment
    end

    percent.labels = r.labels = labels(start, today, 1.week)
    percent.data "#{name} percentage growth", percent_growth

    r.data "#{name} growth rate", growth_rate

  
    draw_graph(percent, "growth.png")
    draw_graph(r, "growth_rate.png")
  
  end
  
end

class SchoolStats < Stats
  # attr_accessor :name, :users, :start_date, :dir, :time_interval
  def initialize(school_name)
    school = School.where(name: school_name).first
    users = User.where(school_id: school.id)
    start_date = school.created_at
    # maybe do something to calculate a better time interval?
    super(school_name, users, start_date, dir="#{school_name}", time_interval=1.day)
  end
end

# ywca = SchoolStats.new("New Haven Free Public Library")
# ywca.growth

class UserStats < Stats
  def initialize()
    name = "All"
    users = User.exclude(school_id: nil)
    start_date = School.min(:created_at)
    dir = "users"
    super(name, users, start_date, dir, time_interval=1.week)
  end

  def dropout_rates(interval=1.week, users=User)
    super(interval, User)
  end


  def dropouts(interval=1.month, users=User)
    super(interval, User)
  end

  def schools
    g = Gruff::Pie.new
    g.title = "School shares"

    School.each do |school|
      count       = school.users.count
      percentage  = (count / users.count.to_f) * 100.0
      g.data(school.name.to_sym, [count])
      puts "#{school.name}: #{count} total users - #{percentage}\% of total"
    end
    # draw_graph('')

    g.write('graphs/schools.png')
  end

  def summary
    puts "********************************************************************"
    puts "All Users:"
    schools
    locale
    platform
    growth
    reading
    puts "********************************************************************"
  end

end


class AllUsers

  def reading
    g = Gruff::Bar.new
    g.title = 'Reading Habits'
    g.labels = {}

    school_users = User.exclude(school_id: nil)
    data  = []

    1.upto(8) do |n|
      g.labels[n-1] = "#{n}w"

      users_on_for_n_weeks = 0
      school_users.each do |u| 
        if (Time.now - u.enrolled_on) > n.weeks
          users_on_for_n_weeks += 1
        end
      end

      data << users_on_for_n_weeks

    end

    g.data(:User_Habits, data)

    g.write('graphs/reading_habits.png')

    g = Gruff::Bar.new
    g.title = 'Stories Read'
    g.labels = {}
    data = []

    school_users_state_tables = []
    StateTable.each do |s| 
      if s.user.school_id != nil
        school_users_state_tables << s
      end

    end

    0.upto(20) do |n|
      g.labels[n] = "#{n}"

      users_who_read_n_books = 0
      school_users_state_tables.each do |u|
        if u.story_number == n
          users_who_read_n_books += 1 
        end
      end
      data << users_who_read_n_books
    end

    g.data(:Stories_Read, data)
    g.write('graphs/stories_read.png')

  end
end

# user_base = AllUsers.new
# user_base.growth






###################################################################################################
# First we want summary statistics for all time. 
# We only want to work with people who have gone through a specific school.
# So round them up. 
# 
# Note: users can be on the program for approximately 6 weeks with 18 stories, +1-6 days
# 
# With just original stories, it's about 3 weeks +1-6 days
# 
# ywca : 200
#
# 
# Summative stats:
#   1. number of users on program
#   2. percentage from each of our schools
#   3. dates of enrollment (perhaps a graph showing enrollment curves)
#   4. how long each user has been on the program
#   5. spanish/english users
#   6. sms -> messenger conversion
#   7. after X weeks, average number of users who've stayed on the program (are still reading stories)
#     - can chart this one out as well. x-axis is # of weeks
#   8. what percent do we lose each week? 
#   9. percent growth in users
#   10. of all users enrolled, on average
#   11. of all people who drop out, what is the average week (plot week-by-week)
#     - percent growth of that
#   12. people who text in and don't convert / total who text in 
#     - people who convert from sms to messenger
#   13. number of interactions over time
#     - % per week for all users (this week, 35%)
#   14. gender/race (upwork job to review pictures and do races)
#   
# School stats:
#   1. all single user stats packaged neatly
#   2. after X weeks, average number of users who've stayed on the program (are still reading stories)
#     - can chart this one out as well. x-axis is # of weeks
#   3. spanish/english users
#   4. how long each user has been on the program
#   5. "how many pages they've read each week"
#   6. direct messages to teachers
#   7. how many students in the school
#     - what percentage of students we've signed up
#   
#   
#   
# Single user stats: 
#   1. how long they've been on the program
#   2. how many reminders they've been sent
#   3. messages along the way
#   4. "how many pages they've read" (and words)
#   5. 
#  
#
#
####################################################################################################
