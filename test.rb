# require_relative 'bin/test'



# User.where(platform: 'fb').each do |u|
#   if u.state_table.last_unique_story == 11
#     u.state_table.update(last_unique_story: 10)
#   end
#   puts "story_number = #{u.state_table.story_number}, last_unique_story = #{u.state_table.last_unique_story}, story_count = #{$story_count}, last_unique_story_read = #{u.state_table.last_unique_story_read?}, last_story_read= #{u.state_table.last_story_read?}"
#   # if u.state_table.story_number < $story_count
#   #   u.state_table.update(last_unique_story: u.state_table.story_number)
#   # else
#   #   u.state_table.update(last_unique_story: $story_count)
#   # end
# end

# User.where(platform: 'sms').each do |u|
#   puts "story_number = #{u.state_table.story_number}, last_unique_story = #{u.state_table.last_unique_story}, story_count = #{$sms_story_count}, last_unique_story_read = #{u.state_table.last_unique_story_read?}, last_story_read= #{u.state_table.last_story_read?}"
#   # if u.state_table.story_number < $sms_story_count
#   #   u.state_table.update(last_unique_story: u.state_table.story_number)
#   # else
#   #   u.state_table.update(last_unique_story: $sms_story_count)
#   # end
# end
