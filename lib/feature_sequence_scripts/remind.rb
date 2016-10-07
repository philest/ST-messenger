Birdv::DSL::ScriptClient.new_script 'remind', 'feature' do
  sequence 'remind' do |recipient|
    # greeting with 5 second delay
    txt = 'scripts.remind_sms[0]'
    send_sms phone_no, txt, 'remind', 'remind2'
  end

  sequence 'remind2' do |recipient|
    txt = 'scripts.remind_sms[1]' 
    send_sms phone_no, txt, 'remind2'
  end
end

