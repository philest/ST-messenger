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
    send_sms phone_no, text=text, current='firstmessage', next_sequence='callToAction'
  end

  sequence 'callToAction' do |phone_no|
    text = 'enrollment.body.call_to_action'
    send_sms phone_no, text, current='callToAction', 'image1'
  end

  # recipients are phone numbers
  sequence 'fbCallToAction' do |phone_no|
    text = 'enrollment.body.fb_call_to_action'
    send_sms phone_no, text, current='fbCallToAction', 'smsCallToAction'
  end

  # recipients are phone numbers
  sequence 'smsCallToAction' do |phone_no|
    text = 'enrollment.body.sms_call_to_action'
    send_sms phone_no, text, current='smsCallToAction', next_sequence='image1'
  end

  sequence 'image1' do |phone_no|
    user = User.where(phone: phone_no).first
    if user.teacher and user.teacher.signature then
      img = 'enrollment.img.has_teacher'
    else
      img = 'enrollment.img.default'
    end
    # handling the YWCA problem
    if !user.school.nil? and user.school.name == 'YWCA' and user.locale == 'es'
      send_mms phone_no, img, 'image1', 'english'
    else
      send_mms phone_no, img, 'image1'
    end

  end

  sequence 'english' do |phone_no|
    txt = "*For English, just text 'English'"
    send_sms phone_no, txt, 'english'
  end

end