Birdv::DSL::ScriptClient.new_script 'day4', 'sms' do
  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    text = 'call_to_action.intro'
    send_sms phone_no, text, current='firstmessage', next_seq='fb_link'
  end
  sequence 'fb_link' do |phone_no|
    text = 'call_to_action.fb'
    send_sms phone_no, text, current='fb_link'
  end
end 

