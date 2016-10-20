Birdv::DSL::ScriptClient.new_script 'demo', 'sms' do

  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    txt = "demo.intro"
    # the new way to do it:
    send_sms phone_no, txt, 'firstmessage', 'callToAction'
  end

  sequence 'callToAction' do |phone_no|
    txt = 'demo.call_to_action'
    send_sms phone_no, txt, 'callToAction', 'image1'
  end
  
  sequence 'image1' do |phone_no|
    img = 'enrollment.img.default'
    send_mms phone_no, img, 'image1'
    User.where(phone: phone_no).first.destroy
  end

  sequence 'firststorydemo' do |phone_no|
    txt = 'enrollment.sms_optin'
    send_sms phone_no, txt, 'firststorydemo', 'storyImage1'
  end

  sequence 'storyImage1' do |phone_no|
    img = 'mms.stories.clouds[0]'
    send_sms phone_no, img, 'storyImage1', 'storyImage2'
  end

  sequence 'storyImage2' do |phone_no|
    img = 'mms.stories.clouds[1]'
    send_sms phone_no, img, 'storyImage2', 'goodbye'
  end

  sequence 'goodbye' do |phone_no|
    puts "saying goodbye..."
    txt = 'demo.thanks'
    send_sms phone_no, txt, 'goodbye'

    User.where(phone: phone_no).first.destroy
  end


end 

