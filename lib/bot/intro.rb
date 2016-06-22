def demo(recipient)
    fb_send_txt( recipient, 
      "Here's how it works.\nReading to your kids at night grows "\
      "their brain.\nWe send stories to you so you always have "\
      "something new to read.\nWe hope you like them!"
    )

    fb_send_txt( recipient, 
      "Here's your first story:"
    )

    intro_story = %w(
                https://s3.amazonaws.com/st-messenger/day1/floating_shoe/floating_shoe1.jpg 
                https://s3.amazonaws.com/st-messenger/day1/floating_shoe/floating_shoe1.jpg
                )

  	intro_story.each do |story_page|
     fb_send_pic( recipient, story_page )
  	end
    
    fb_send_txt( recipient, 
      "We hope you love these."
    )

  # save user in the database.
  # TODO : update an existing DB entry to coincide the fb_id with phone_number
  begin
    fields = "first_name,last_name,profile_pic,locale,timezone,gender"
    data = HTTParty.get("https://graph.facebook.com/v2.6/#{recipient['id']}?fields=#{fields}&access_token=#{ENV['FB_ACCESS_TKN']}")
    name = data["first_name"] + " " + data["last_name"]
  rescue
    User.create(:fb_id => recipient["id"])
  else
    puts "successfully found user data for #{name}"
    last_name = data['last_name']
    regex = /[a-zA-Z]*( )?#{last_name}/i  # if child's last name matches, go for it
    begin
      candidates = User.where(:child_name => regex, :fb_id => nil)
      if candidates.all.empty? # add a new user w/o child info (no matches)
        User.create(:fb_id => recipient['id'], :name => name, :gender => data['gender'], :locale => data['locale'], :profile_pic => data['profile_pic'])
      else
        # implement stupid fb_name matching to existing user matching
        candidates.order(:enrolled_on).first.update(:fb_id => recipient['id'], :name => name, :gender => data['gender'], :locale => data['locale'], :profile_pic => data['profile_pic'])
      end
    rescue Sequel::Error => e
      p e.message + " did not insert, already exists in db"
    end # rescue - db transaction
  end # rescue - httparty
end