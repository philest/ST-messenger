Birdv::DSL::ScriptClient.new_script 'day9', 'feature' do
  sequence 'firstmessage' do |phone_no|
    txt = 'scripts.intro_sms.__poc__[2]'
    send_sms phone_no, txt, 'firstmessage', 'verse1'
  end

  sequence 'verse1' do |phone_no|
    txt = 'feature.poems.chomp[0]'
    send_sms phone_no, txt, 'verse1', 'verse2'
  end

  sequence 'verse2' do |phone_no|
    txt = 'feature.poems.chomp[1]'
    send_sms phone_no, txt, 'verse2', 'verse3'
  end

  sequence 'verse3' do |phone_no|
    txt = 'feature.poems.chomp[2]'
    send_sms phone_no, txt, 'verse3'
  end

  # sequence 'goodbye' do |phone_no|
  #   txt = 'scripts.outro.__poc__[1]'
  #   send_sms phone_no, txt, 'goodbye'
  # end
end

