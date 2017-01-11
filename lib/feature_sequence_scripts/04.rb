Birdv::DSL::ScriptClient.new_script 'day4', 'feature' do


  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    txt = 'scripts.intro_sms.__poc__[3]'
    send_sms phone_no, txt, 'firstmessage', 'verse1'
  end

  sequence 'verse1' do |phone_no|
    # send out coon story
    txt = 'feature.poems.whale[0]'

    send_sms phone_no, txt, 'verse1', 'verse2'
  end

  # No button on the first day! 
  sequence 'verse2' do |phone_no|
    # one more button
    txt = 'feature.poems.whale[1]'
    send_sms phone_no, txt, 'verse2', 'verse3'
  end

    # No button on the first day! 
  sequence 'verse3' do |phone_no|
    # one more button
    txt = 'feature.poems.whale[2]'
    send_sms phone_no, txt, 'verse3', 'goodbye'
  end


  # sequence 'goodbye' do |phone_no|
  #   puts "saying goodbye..."

  #   txt = 'scripts.outro.__poc__[1]'
  #   send_sms phone_no, txt, 'goodbye'
  # end
end 

