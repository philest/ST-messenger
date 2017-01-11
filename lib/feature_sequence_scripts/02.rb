Birdv::DSL::ScriptClient.new_script 'day2', 'feature' do

	# recipients are phone numbers
	sequence 'firstmessage' do |phone_no|
		txt = 'scripts.first_book.__poc__'
		send_sms phone_no, txt, 'firstmessage', 'verse1'
	end

	sequence 'verse1' do |phone_no|
		txt = 'feature.poems.hero[0]'
		send_sms phone_no, txt, 'verse1', 'verse2'
	end

	sequence 'verse2' do |phone_no|
		txt = 'feature.poems.hero[1]'
		send_sms phone_no, txt, 'verse2', 'goodbye'
	end

	# sequence 'goodbye' do |phone_no|
	# 	txt = 'scripts.outro.__poc__[0]'
	# 	send_sms phone_no, txt, 'goodbye'
	# end


end 

