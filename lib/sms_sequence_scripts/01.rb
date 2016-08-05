Birdv::DSL::ScriptClient.new_script 'day1', 'sms' do

  day 1

  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    user = User.where(phone: phone_no).first
    if user.teacher and user.teacher.signature then
      puts "has teacher, using teacher text"
      txt_sprint = 'enrollment.body_sprint.has_teacher'
    elsif user.school and user.school.signature then
      puts "has school, using school text"
      txt_sprint = 'enrollment.body_sprint.has_school'
    else
      puts "has none, using default text"
      txt_sprint = 'enrollment.body_sprint.has_none'
    end

    puts "sending intro txt (sprint)..."

    # because it'll be annoying to try to get the carrier from here, just send these texts as if it's for Sprint.
    first_msg = txt_sprint << '.first'
    second_msg = txt_sprint << '.second'
    
    send phone_no, first_msg, 'sms'

    # the new way to delay would look something like this.....
    delay SMS_WAIT do 
      send phone_no, second_msg, 'sms'
    end

    delay phone_no, 'image1', SMS_WAIT
  end


  sequence 'image1' do |phone_no|
    user = User.where(phone: phone_no).first
    if user.teacher and user.teacher.signature then
      img = 'http://d2p8iyobf0557z.cloudfront.net/day1/twilio-mms-final.jpg'
    else
      img = 'http://d2p8iyobf0557z.cloudfront.net/day1/twilio-mms-nhv.jpg'
    end
    puts "sending first image..."

    # the new way to do it:
    send phone_no, img, 'mms'
    
  end


end 

