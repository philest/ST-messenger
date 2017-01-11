Birdv::DSL::ScriptClient.new_script 'day9', 'sms' do
  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    txt = 'scripts.intro_sms.__poc__[2]'
    puts "sending intro txt..."
    send_sms phone_no, txt, 'firstmessage', 'image1'
  end

  sequence 'image1' do |phone_no|
    img = 'mms.stories.floating_shoe[0]'
    puts "sending first image..."
    send_mms phone_no, img, 'image1', 'image2'
  end
 
  sequence 'image2' do |phone_no|
    puts "sending second image..."
    img = 'mms.stories.floating_shoe[1]'
    send_mms phone_no, img, 'image2', 'goodbye'
  end

  # sequence 'goodbye' do |phone_no|
  #   puts "saying goodbye..."

  #   txt = 'scripts.outro.__poc__[3]'
  #   send_sms phone_no, txt, 'goodbye'
  # end

end 




