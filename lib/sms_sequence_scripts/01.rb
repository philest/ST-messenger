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
    first_msg = txt_sprint + '.first'
    

    # in send(), add an extra parameter: next sequence name, so that we can call on that in the callback

    send phone_no, first_msg, 'sms'

    # the new way to delay would look something like this.....
    # delay_inline SMS_WAIT do 
    #   send phone_no, second_msg, 'sms'
    # end

    delay phone_no, 'firstmessage2', SMS_WAIT
  end


    # recipients are phone numbers
  sequence 'firstmessage2' do |phone_no|
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
    second_msg = txt_sprint + '.second'
    
    send phone_no, second_msg, 'sms'

    # # the new way to delay would look something like this.....
    # delay_inline SMS_WAIT do 
    #   send phone_no, second_msg, 'sms'
    # end

    # instead of waiting for a delay, wait for the callback response from st-enroll

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

