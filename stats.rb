require_relative('bin/production.rb')
require 'gruff'


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
    schools = {}

    percent = Gruff::Line.new
    percent.title = 'Growth over time (%)'
    percent_growth = []

    date_index = 0

    date = users.where{enrolled_on >= start}.min(:enrolled_on) + 1.week

    prev_week = 6 # gotta start somewhere
    while date < today
      formatted_date = "#{date.month}/#{date.day}"
      g.labels[date_index]  = formatted_date
      # or should we only be taking from schools? 

      # enrollment for everyone
      enrollment = users.where{enrolled_on <= date}.count
      enrollment_growth << enrollment
      percent_growth << (enrollment - prev_week) / prev_week.to_f

      School.each do |s|
        school_enrollment = users.where{enrolled_on < date}.where(school_id: s.id).count
        schools[s.name] ||= {enrollment: [], prev_week: 0, percent_growth: []}
        schools[s.name][:enrollment] << school_enrollment
        school_prev_week = schools[s.name][:prev_week]
        if school_prev_week == 0 and school_enrollment == 0
          schools[s.name][:percent_growth] << 0.0
        elsif school_prev_week == 0 and school_enrollment > 0
          schools[s.name][:percent_growth] << 0.2
          # schools[s.name][]
        else
          schools[s.name][:percent_growth] << (school_enrollment - school_prev_week) / school_prev_week.to_f
        end

        schools[s.name][:prev_week] = school_enrollment
      end
      date_index += 1
      date += 1.week
      prev_week = enrollment
    end

    schools.each do |name, school_users|
      puts "#{school_users}"
      g.data name.to_s, school_users[:enrollment]
      # school_users[:percent_growth].map! {|x| x.nan? ? 0.0 : x*100 }
      # percent.data name.to_s, school_users[:percent_growth]
    end

    g.data :Users, enrollment_growth
    g.write('graphs/enrollment.png')

    percent_growth.map! {|x| x.nan? ? 0.0 : x*100 }

    percent.labels = g.labels
    percent.data :Users, percent_growth

    percent.write('graphs/growth.png')

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

user_base = AllUsers.new
user_base.growth






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
