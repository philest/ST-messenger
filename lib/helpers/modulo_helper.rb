module ModuloHelper

  def mod_story(user)
    st_no = user.state_table.story_number
    n = st_no + 1
    last_unique = user.state_table.last_unique_story

    # if our current story number is greater than those available
    if st_no > $story_count
      # if our last unique story index is less than the total count of unique stories
      if last_unique < $story_count
        # increment last_unique bc we are definitely going to send that one.\
        # DO NOT increment story_number
        puts "sending the next unique story..."
        user.state_table.update(last_story_read?: false,
                                last_unique_story: last_unique + 1, 
                                last_unique_story_read?: false)
        # do not increment story_number so next time we'll get back to the same story we were going to read
        return last_unique + 1
      else # send mod'd story index
        mod = (st_no % $story_count) + 1
        return mod == 1 ? 2 : mod
      end

    else # we have seen fewer stories than those available
      user.state_table.update(story_number: n, 
                              last_story_read?: false,
                              last_unique_story: last_unique + 1)
      return user.state_table.story_number
    end


  end

end