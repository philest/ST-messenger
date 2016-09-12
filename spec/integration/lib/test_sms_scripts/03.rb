Birdv::DSL::ScriptClient.new_script 'day3', 'sms' do

  # day 3

  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    txt = "scripts.teacher_intro_sms"
    puts "sending intro txt..."
    send_sms phone_no, txt, 'image1'

    # delay the conventional SMS delay
    # delay phone_no, 'image1', SMS_WAIT
  end

  sequence 'image1' do |phone_no|
    # send out coon story
    img = 'mms.stories.clouds[0]'
    puts "sending first image..."
    send_mms phone_no, img, 'image2'

    # delay phone_no, 'image2', MMS_WAIT
  end

  # No button on the first day! 
  sequence 'image2' do |phone_no|
    # one more button
    puts "sending second image..."
    img = 'mms.stories.clouds[1]'
    send_mms phone_no, img, 'goodbye'

    # delay phone_no, 'goodbye', MMS_WAIT
  end

  sequence 'goodbye' do |phone_no|
    puts "saying goodbye..."

    txt = 'scripts.buttons.window_text[1]'
    send_sms phone_no, txt
  end
end 

