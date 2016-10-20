Birdv::DSL::ScriptClient.new_script 'remind', 'sms' do
  sequence 'remind' do |phone_no|
    # greeting with 5 second delay
    txt = 'scripts.remind_sms.__poc__[0]'
    send_sms phone_no, txt, 'remind', 'remind2'
  end

  sequence 'remind2' do |phone_no|
    txt = 'scripts.remind_sms.__poc__[1]' 
    send_sms phone_no, txt, 'remind2'
  end
end

