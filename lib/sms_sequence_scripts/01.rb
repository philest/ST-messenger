Birdv::DSL::ScriptClient.new_script 'day1', 'sms' do
  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    text = 'scripts.intro_sms.__poc__[0]'
    send_sms phone_no, text=text, current='firstmessage', next_sequence='callToAction'
  end

  sequence 'callToAction' do |phone_no|
    text = 'scripts.enrollment.call_to_action'
    user = User.where(phone: phone_no).first
     # handling the YWCA problem
    if !user.school.nil? and user.school.name == 'YWCA' and user.locale == 'es'
      send_sms phone_no, text, current='callToAction', 'english'
    else
      send_sms phone_no, text, current='callToAction'
    end
  end

  # sequence 'image1' do |phone_no|
  #   img = 'scripts.enrollment.img.__poc__'
    
  #   user = User.where(phone: phone_no).first
  #   # handling the YWCA problem
  #   if !user.school.nil? and user.school.name == 'YWCA' and user.locale == 'es'
  #     send_mms phone_no, img, 'image1', 'english'
  #   else
  #     send_mms phone_no, img, 'image1'
  #   end

  # end

  sequence 'english' do |phone_no|
    txt = "*For English, just text 'English'"
    send_sms phone_no, txt, 'english'
  end
end