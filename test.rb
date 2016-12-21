require_relative 'bin/production'

User.where(platform: 'fb').each do |u|
  # if u.state_table.last_unique_story == 11
  #   u.state_table.update(last_unique_story: 10)
  # end
  if u.state_table.story_number < 10
    u.state_table.update(last_unique_story: u.state_table.story_number)
  else
    u.state_table.update(last_unique_story: 10)
  end
  puts "story_number = #{u.state_table.story_number}, last_unique_story = #{u.state_table.last_unique_story}, story_count = #{$story_count}, last_unique_story_read = #{u.state_table.last_unique_story_read?}, last_story_read= #{u.state_table.last_story_read?}"
end

User.where(platform: 'sms').each do |u|
  if u.state_table.story_number < 10
    u.state_table.update(last_unique_story: u.state_table.story_number)
  else
    u.state_table.update(last_unique_story: 10)
  end
  puts "story_number = #{u.state_table.story_number}, last_unique_story = #{u.state_table.last_unique_story}, story_count = #{$sms_story_count}, last_unique_story_read = #{u.state_table.last_unique_story_read?}, last_story_read= #{u.state_table.last_story_read?}"
end
