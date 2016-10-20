Birdv::DSL::ScriptClient.new_script 'day6', 'sms' do
  # recipients are phone numbers
  sequence 'firstmessage' do |phone_no|
    text = 'mms.call_to_action.intro.__poc__'
    send_sms phone_no, text, current='firstmessage', 'fb_link'
  end

  sequence 'fb_link' do |phone_no|
    text = 'mms.call_to_action.fb'
    send_sms phone_no, text, current='fb_link'
  end
end 

