class MessengerCourier
  include Sidekiq::Worker
  def perform(name, fb_id, title, length)
    base_url = "https://s3.amazonaws.com/st-messenger/old_stories/"
    story_url = base_url + title
    length.times do |page|
      page_url = "#{story_url}/#{title}#{page+1}.jpg" 
      FB.send_pic(fb_id, page_url)
    end

    # TODO, add completed to a DONE pile. Then we can increment story num.
    # But for now,
    # DB[:users].where(:name => name).update(:story_number=>Sequel.expr(:story_number)+1)
  end
end
