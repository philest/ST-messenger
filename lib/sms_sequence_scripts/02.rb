Birdv::DSL::ScriptClient.new_script 'day2', 'sms' do

	# recipients are phone numbers
	sequence 'firstmessage' do |phone_no|
		txt = "scripts.teacher_intro_sms[1]"
		puts "sending intro txt..."

		# the new way to do it:
		send_sms phone_no, txt, 'firstmessage', 'image1'

		# there is a timer within send_sms() that checks shit

		# delay the conventional SMS delay
		# delay phone_no, 'image1', SMS_WAIT
	end


	sequence 'image1' do |phone_no|
		# send out coon story
		img = 'mms.stories.hero[0]'
		puts "sending first image..."

		# the new way to do it:
		send_mms phone_no, img, 'image1', 'image2'

		# delay phone_no, 'image2', MMS_WAIT
	end

	# No button on the first day! 
	sequence 'image2' do |phone_no|
		# one more button
		puts "sending second image..."
		img = 'mms.stories.hero[1]'

		# the new way to do it:
		send_mms phone_no, img, 'image2', 'goodbye'

		# delay phone_no, 'goodbye', MMS_WAIT
	end

	sequence 'goodbye' do |phone_no|
		puts "saying goodbye..."

		txt = 'scripts.buttons.window_text[0]'

		# the new way to do it:
		send_sms phone_no, txt, 'goodbye'
	end
end 

