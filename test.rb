
require 'httparty'
# require_relative 'lib/helpers/generate_phone_image'
require_relative 'config/initializers/aws'
require_relative 'bin/local'
# puts UserStats.new.dropouts
# 


s = School.create(signature: "ST Prep", code: "test|test-es")
t = Teacher.create(signature: "Mr. McPeek", email: "david.mcpeek@yale.edu")
t.signup_user(User.create(first_name: "David", last_name: "McPeek", phone: "8186897323"))
t.signup_user(User.create(first_name: "Aubrey", last_name: "Wahl", phone: "1112333333"))
t.signup_user(User.create(first_name: "Aubrey", last_name: "Wahl", phone: "4395575555"))


# users = SchoolStats.new("New Haven Free Public Library")
# users.get_conversation("2034352867")
if School.where(name: "TEST").first.nil?
  School.create(name: "TEST", code: "test|test-es", signature: "Rocky Mountain Prep")
end

school = School.where(name: "TEST").first

teacher = Teacher.where(id: Teacher.max(:id)).first
# teacher = Teacher.create(signature: "My Asshole")
# school.signup_teacher(teacher)

PhoneImage.create_image(teacher, school)

# FlyerImage.create_image("RMP1")

# School.each do |s|
#   PhoneImage.create_image(s.code.split('|').first.upcase)
# end


# puts HTTParty.post("http://localhost:5000/signup",
#   body: {
#     email: 'david.mcpeek@yale.edu',
#     password: 'ywca',
#     signature: 'Mr. McPeek'
#   }
# )


# HTTParty.post(
#   "http://localhost:4567/signin",
#   # include teacher data in the body
#   # we don't need very much in each teacher session
#   body: {
#     teacher: Teacher.first.to_json,
#     school: School.first.to_json,
#     secret: 'our little secret'
#   }
# )

# ywca = SchoolStats.new("New Haven Free Public Library")

# ywca.growth
# ywca.enrollment
# ywca.locale
# ywca.platform
# ywca.dropouts
# 

# x = ywca.text_replies


# total = 0
# received = 0
# thanks = 0

# x.each do |z, y|
#   # puts "total messages = #{y[:convo].size}, received = #{y[:received].size}"
#   total += y[:convo].size
#   received += y[:received].size
#   tx = /(thank)|(gracias)/i
#   for msg in y[:received]
#     if msg.body.match(tx)
#       thanks += 1
#       puts msg.body
#     end
#   end
# end


# g = Gruff::Bar.new
# g.title = "Family engagement with the YW"
# g.labels = {0 => "Parent replies", 1 => "Thanks you's"}
# g.data "Number of replies and 'thanks' families have sent", [received, 37]

# g.write('graphs/schools/YWCA/user_replies.png')
# puts "total = #{total}, received = #{received}, thanks = #{thanks}"




# total = 1656, received = 320











# X = User.map do |u|
#   st = u.state_table
#   st.updated_at - u.enrolled_on
# end


# class Test
#   def hi(x)
#     puts x
#   end
# end

# class Fun < Test
#   def hi(x, y)
#     super(x)
#   end
# end

# Fun.new.hi("there", "bitch")