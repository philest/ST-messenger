module ContactHelpers

  def name_codes(str, id)
    user = User.where(:fb_id => id).first
    # if fb_id didn't work, maybe we're on the wrong platform
    if user.nil?
      user = User.where(phone: id).first
    end

    if user
      parent  = user.first_name.nil? ? "" : user.first_name
      child   = user.child_name.nil? ? "your child" : user.child_name.split[0]
      
      if !user.teacher.nil?
        sig = user.teacher.signature
        teacher = sig.nil?           ? "StoryTime" : sig
      else
        teacher = "StoryTime"
      end

      str = str.gsub(/__TEACHER__/, teacher)
      str = str.gsub(/__PARENT__/, parent)
      str = str.gsub(/__CHILD__/, child)
      return str
    else # just return what we started with. It's 
      str = str.gsub(/__TEACHER__/, 'StoryTime')
      str = str.gsub(/__PARENT__/, '')
      str = str.gsub(/__CHILD__/, 'your child')
      return str
    end
  end

  def translate_sms(phone, text)
    usr = User.where(phone: phone).first
    I18n.locale = usr.locale

    if text.nil? or text.empty? then 
      return text   
    end

    trans = I18n.t text
    if trans.is_a? Array
      return name_codes trans[@script_day - 1], phone 
    else
      return names_codes trans, phone
    end
    
  rescue NoMethodError => e
    p e.message + " usr doesn't exist, can't translate"
    return false
  end

  def send_sms( phone, text )
    text = translate_sms( phone, text )
    if text == false
      puts "something went wrong, can't translate this text (likely, the phone # doesn't belong to a user in the system)"
      return
    end
    HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/txt", 
      body: {
        recipient: phone,
        text: text
      }
    )
  end

  # perhaps mms should also use the send_story function...
  def send_mms( phone, img_url )
    HTTParty.post("#{ENV['ST_ENROLL_WEBHOOK']}/mms", 
      body: {
        recipient: phone,
        img_url: img_url
      }
    )
  end

  def email_admins(subject, body)
    Pony.mail(:to => 'phil.esterman@yale.edu',
              :cc => 'david.mcpeek@yale.edu',
              :from => 'david.mcpeek@yale.edu',
              :headers => { 'Content-Type' => 'text/html' },
              :subject => subject,
              :body => body)
  end

  
end
