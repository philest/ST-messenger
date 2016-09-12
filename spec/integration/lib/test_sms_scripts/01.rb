Birdv::DSL::ScriptClient.new_script 'day1', 'sms' do

  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    user = User.where(phone: phone_no).first
    if user.teacher and user.teacher.signature then
      text = 'enrollment.body.has_teacher'
    elsif user.school and user.school.signature then
      text = 'enrollment.body.has_school'
    else
      text = 'enrollment.body.has_none'
    end
    puts "sending intro txt..."
    # in send(), add an extra parameter: next sequence name, so that we can call on that in the callback
    send_sms phone_no, text=text, next_sequence='smsCallToAction'
  end

  # recipients are phone numbers
  sequence 'smsCallToAction' do |phone_no|
    text = 'enrollment.body.sms_call_to_action'
    send_sms phone_no, text, 'fbCallToAction'
  end

  # recipients are phone numbers
  sequence 'fbCallToAction' do |phone_no|
    text = 'enrollment.body.fb_call_to_action'
    send_sms phone_no, text, 'image1'
  end


  sequence 'image1' do |phone_no|
    user = User.where(phone: phone_no).first
    if user.teacher and user.teacher.signature then
      img = 'enrollment.img.has_teacher'
    else
      img = 'enrollment.img.default'
    end
    puts "sending first image..."

    send_mms phone_no, img
  end


end 

