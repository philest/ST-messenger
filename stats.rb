require_relative('bin/production.rb')
require 'gruff'
require 'fileutils'


class Stats
  attr_accessor :name, :users, :start_date, :dir, :time_interval

  def initialize(name, user_query, start_date, dir="", time_interval=1.day)
    @name = name
    @users = user_query
    @start_date = start_date
    @dir = dir
    @time_interval = time_interval
  end

  def draw_graph(graph, url)
  end

  def growth
    today = Time.now + 1.week
    g = Gruff::Line.new
    g.title = "Enrollment over time"
    g.labels = {}
    enrollment_growth = []

    percent = Gruff::Line.new
    percent.title = "\% growth over time"
    percent_growth = []

    r = Gruff::Line.new
    r.title = "Growth rate (users/week)"
    growth_rate = []

    date_index = 0

    start = start_date
    date = users.where{enrolled_on >= start}.min(:enrolled_on)

    # seed with the users who enrolled in the first time_interval
    interval = time_interval
    prev_week = users.where{(enrolled_on >= date) && (enrolled_on < (date + interval))}.count

    # begin after those initial users have already gone
    date += time_interval

    # prev_week = 1
    while date < today
      formatted_date = "#{date.month}/#{date.day}"
      g.labels[date_index]  = formatted_date

       # enrollment for everyone
      enrollment = users.where{enrolled_on <= date}.count
      enrollment_growth << enrollment
      percent_growth << ((enrollment - prev_week) / prev_week.to_f ) * 100

      growth_rate << (enrollment - prev_week)

      date_index += 1
      date += 1.week
      prev_week = enrollment
    end

    percent.labels = r.labels = g.labels 
    percent.data "#{name} percentage growth", percent_growth

    r.data "#{name} growth rate", growth_rate

    g.data "#{name} users", enrollment_growth

    dirname = "graphs/#{dir}"
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    base_url = "graphs/#{dir}"

    percent.write("#{base_url}/growth.png")
    g.write("#{base_url}/enrollment.png")
    r.write("#{base_url}/growth_rate.png")

  end

end

class SchoolStats < Stats
  # attr_accessor :name, :users, :start_date, :dir, :time_interval
  def initialize(school_name)
    school = School.where(name: school_name).first
    users = User.where(school_id: school.id)
    start_date = school.created_at
    # maybe do something to calculate a better time interval?
    super(school_name, users, start_date, dir="schools/#{school_name}", time_interval=1.day)
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
end

users = UserStats.new
users.growth


# class SchoolStats
#   attr_accessor :school, :users

#   def initialize(name)
#     @school = School.where(name: name).first
#     @users = User.where(school_id: @school.id)
#   end 

#   def growth(opt="all")
#     start = school.created_at
#     today = Time.now + 1.week

#     g = Gruff::Line.new
#     g.title = "Enrollment over time: #{school.name}"
#     g.labels = {}
#     enrollment_growth = []

#     percent = Gruff::Line.new
#     percent.title = 'Growth over time (%)'
#     percent_growth = []

#     r = Gruff::Line.new
#     r.title = "Growth rate (users/week)"
#     growth_rate = []

#     date_index = 0

#     # the first day any user enrolled in this school
#     date = users.where{enrolled_on >= start}.min(:enrolled_on)

#     time_interval = 1.day

#     # seed with the users who enrolled in the first time_interval
#     prev_week = users.where{(enrolled_on >= date) && (enrolled_on < (date + time_interval))}.count

#     # begin after those initial users have already gone
#     date += time_interval

#     puts "prev_week = #{prev_week}"
#     # prev_week = 1
#     while date < today
#       formatted_date = "#{date.month}/#{date.day}"
#       g.labels[date_index]  = formatted_date

#        # enrollment for everyone
#       enrollment = users.where{enrolled_on <= date}.count
#       enrollment_growth << enrollment
#       percent_growth << ((enrollment - prev_week) / prev_week.to_f ) * 100

#       growth_rate << (enrollment - prev_week)

#       date_index += 1
#       date += 1.week
#       prev_week = enrollment
#     end

#     percent.labels = r.labels = g.labels 
#     percent.data "#{school.name} growth", percent_growth

#     r.data "#{school.name} growth rate", growth_rate

#     g.data "#{school.name} users", enrollment_growth

#     dirname = "graphs/schools/#{school.name}/"
#     unless File.directory?(dirname)
#       FileUtils.mkdir_p(dirname)
#     end

#     base_url = "graphs/schools/#{school.name}/"

#     case opt
#     when 'percent'
#       percent.write("#{base_url}growth.png")

#     when 'absolute', 'abs'
#       g.write("#{base_url}enrollment.png")

#     when 'rate'
#       r.write("#{base_url}growth_rate.png")
#     else
#       percent.write("#{base_url}growth.png")
#       g.write("#{base_url}enrollment.png")
#       r.write("#{base_url}growth_rate.png")

#     end
    
#   end
# end




class AllUsers

  def total
    t = 0
    School.each {|s| t += s.users.count}
    return t
  end

  def schools
    g = Gruff::Pie.new
    g.title = "School shares"

    School.each do |school|
      count       = school.users.count
      percentage  = (count / total.to_f) * 100.0
      g.data(school.name.to_sym, [count])
      puts "#{school.name}: #{count} total users - #{percentage}\% of total"
    end
    g.write('graphs/schools.png')
  end

  def growth
    start   = School.min(:created_at)
    today   = Time.now + 1.week
    users = User.exclude(school_id: nil)
    g = Gruff::Line.new
    g.title = 'Enrollment over time'
    g.labels = {}
    enrollment_growth = []

    percent = Gruff::Line.new
    percent.title = 'Growth over time (%)'
    percent_growth = []

    r = Gruff::Line.new
    r.title = "Growth rate (users/week)"
    growth_rate = []

    date_index = 0

    date = users.where{enrolled_on >= start}.min(:enrolled_on)
    time_interval = 1.week
    prev_week = users.where{(enrolled_on >= date) && (enrolled_on < (date + time_interval))}.count

    date += time_interval

    # prev_week = 6 # gotta start somewhere
    while date < today
      formatted_date = "#{date.month}/#{date.day}"
      g.labels[date_index]  = formatted_date
      # or should we only be taking from schools? 

      # enrollment for everyone
      enrollment = users.where{enrolled_on <= date}.count
      enrollment_growth << enrollment
      percent_growth << ((enrollment - prev_week) / prev_week.to_f) * 100

      growth_rate << (enrollment - prev_week)

      date_index += 1
      date += 1.week
      prev_week = enrollment
    end

    percent.labels = r.labels = g.labels 

    g.data :Users, enrollment_growth
    percent.data :Users, percent_growth
    r.data "User Growth Rate", growth_rate

    g.write('graphs/enrollment.png')
    percent.write('graphs/growth.png')
    r.write("graphs/growth_rate.png")
      

    # take weekly intervals... find out the number of users that enrolled_at before that week's end
  end

  def locale
    num_english = User.where(locale: 'en').count
    num_spanish = User.where(locale: 'es').count
    puts "English: #{num_english} - Spanish: #{num_spanish}"

    g = Gruff::Pie.new
    g.title = "Language"
    g.data(:English, num_english)
    g.data(:Spanish, num_spanish)
    g.write('graphs/language.png')
  end

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

  def platform
    num_fb      = User.where(platform: 'fb').count
    num_sms     = User.where(platform: 'sms').count
    num_feature = User.where(platform: 'feature').count
    g = Gruff::Pie.new
    g.title = "Platform share"
    g.data(:Facebook, num_fb)
    g.data(:SMS, num_sms)
    g.data(:Feature, num_feature)
    g.write('graphs/platform.png')
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
