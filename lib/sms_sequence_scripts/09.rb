Birdv::DSL::ScriptClient.new_script 'day9', 'sms' do
  sequence 'firstmessage' do |phone_no|
    txt = 'scripts.intro_sms.__poc__[1]'
    puts "sending intro txt..."
    send_sms phone_no, txt, 'firstmessage', 'image1'
  end

  sequence 'image1' do |phone_no|
    img = 'mms.stories.moon[0]'
    puts "sending first image..."
    send_mms phone_no, img, 'image1'
  end

end 

