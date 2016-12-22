module SchoolCodeMatcher

  def is_matching_code?(body_text)
     # get all available codes...
      all_codes =  School.map(:code).compact
      all_codes += Teacher.map(:code).compact
      puts "all codes (teachers, schools) = #{all_codes}"
      all_codes = all_codes.map {|c| c.delete(' ').delete('-').downcase }
      # need to split up the codes by individual english/spanish
      all_codes = all_codes.inject([]) do |result, elt|
        # should I just be taking the English code part? no of course not bc we have spanish users
        result += elt.split('|')
      end
      return all_codes.include? body_text
  end

end