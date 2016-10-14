require_relative 'stats'

# puts UserStats.new.dropouts

ywca = SchoolStats.new("YWCA")

# ywca.growth
# ywca.dropouts
puts ywca.growth








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