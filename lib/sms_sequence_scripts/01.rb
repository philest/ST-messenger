Birdv::DSL::ScriptClient.new_script 'day1', 'sms' do

  day 1

  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    user = User.where(phone: phone_no).first

    if user.teacher and user.teacher.signature then
      puts "has teacher, using teacher text"
      txt = 'enrollment.body.has_teacher'
      txt_sprint = 'enrollment.body_sprint.has_teacher.first'
    elsif user.school and user.school.signature then
      puts "has school, using school text"
      txt = 'enrollment.body.has_school'
      txt_sprint = 'enrollment.body_sprint.has_school.first'
    else
      puts "has none, using default text"
      txt = 'enrollment.body.has_none'
      txt_sprint = 'enrollment.body_sprint.has_none.first'
    end

    puts "sending intro txt, part 1 (sprint)..."

    # because it'll be annoying to try to get the carrier from here, just send these texts as if it's for Sprint.
    send phone_no, txt_sprint, 'sms'

    # delay the conventional SMS delay
    delay phone_no, 'firstmessage2', SMS_WAIT

    # the new way to delay would look something like this.....
    # delay phone_no do 
    #   # do something
    #   send phone_no, txt_sprint, 'sms'
    # end
  end

  sequence 'firstmessage2' do |phone_no|
    user = User.where(phone: phone_no).first

    if user.teacher and user.teacher.signature then
      puts "has teacher, using teacher text"
      txt = 'enrollment.body.has_teacher'
      txt_sprint = 'enrollment.body_sprint.has_teacher.second'
    elsif user.school and user.school.signature then
      puts "has school, using school text"
      txt = 'enrollment.body.has_school'
      txt_sprint = 'enrollment.body_sprint.has_school.second'
    else
      puts "has none, using default text"
      txt = 'enrollment.body.has_none'
      txt_sprint = 'enrollment.body_sprint.has_none.second'
    end

    # because it'll be annoying to try to get the carrier from here, just send these texts as if it's for Sprint.
    send phone_no, txt_sprint, 'sms'

    delay phone_no, 'image1', SMS_WAIT
  end


  sequence 'image1' do |phone_no|
    user = User.where(phone: phone_no).first
    if user.teacher and user.teacher.signature then
      img = 'http://d2p8iyobf0557z.cloudfront.net/day1/twilio-mms-final.jpg'
    else
      img = 'http://d2p8iyobf0557z.cloudfront.net/day1/twilio-mms-nhv.jpg'
    end
    "sending first image..."

    # the new way to do it:
    send phone_no, img, 'mms'

  end


end 

