def intro(recipient)
    fb_send_txt( recipient, 
      "Here's how it works.\nReading to your kids at night grows "\
      "their brain.\nWe send stories to you so you always have "\
      "something new to read.\nWe hope you like them!"
    )

    fb_send_txt( recipient, 
      "Here's your first story:"
    )

    intro_story = %w(
                http://s33.postimg.org/z2io2l1gv/floating_Shoe1.jpg 
                http://s33.postimg.org/487qtv4bz/floating_Shoe2.jpg
                )

  	intro_story.each do |story_page|
     fb_send_pic( recipient, story_page )
  	end
    
    fb_send_txt( recipient, 
      "We hope you love these."
    )

  	# save user in the database.
    begin
      users = DB[:users] 
      begin
        fb_name = HTTParty.get("https://graph.facebook.com/v2.6/#{recipient['id']}?fields=first_name,last_name&access_token=#{ENV['FB_ACCESS_TKN']}")
        name = fb_name["first_name"] + " " + fb_name["last_name"]
      rescue HTTParty::Error
        name = ""
      else
        puts "successfully found name"
      end

      begin 
        users.insert(:name => name, :fb_id => recipient["id"])
        puts "inserted #{name}:#{recipient} into the users table"
      rescue Sequel::UniqueConstraintViolation => e
        p e.message
        puts "did not insert, already exists in db"
      rescue Sequel::Error => e
        p e.message
        puts "failure"
      end
    rescue Sequel::Error => e
      p e.message
    end
end