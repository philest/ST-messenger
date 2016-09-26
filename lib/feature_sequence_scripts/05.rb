Birdv::DSL::ScriptClient.new_script 'day5', 'feature' do
  sequence 'firstmessage' do |phone_no|
    txt = "scripts.teacher_intro_sms[1]"
    send_sms phone_no, txt, 'firstmessage', 'verse1'
  end

  sequence 'verse1' do |phone_no|
    txt = 'feature.poems.seed[0]'
    send_sms phone_no, txt, 'verse1', 'verse2'
  end

  sequence 'verse2' do |phone_no|
    txt = 'feature.poems.seed[1]'
    send_sms phone_no, txt, 'verse2', 'verse3'
  end

  sequence 'verse3' do |phone_no|
    txt = 'feature.poems.seed[2]'
    send_sms phone_no, txt, 'verse3', 'verse4'
  end

  sequence 'verse4' do |phone_no|
    txt = 'feature.poems.seed[3]'
    send_sms phone_no, txt, 'verse4', 'goodbye'
  end

  sequence 'goodbye' do |phone_no|
    txt = 'scripts.buttons.window_text[1]'
    send_sms phone_no, txt, 'goodbye'
  end
end 

