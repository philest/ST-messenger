Birdv::DSL::ScriptClient.new_script 'day2', 'sms' do

	day 2

	# recipients are phone numbers
	sequence 'firstmessage' do |phone_no|
		txt = "scripts.teacher_intro"
		puts "sending intro txt..."

		# the new way to do it:
		send phone_no, txt, 'sms'

		# delay the conventional SMS delay
		delay phone_no, 'image1', SMS_WAIT
	end


	sequence 'image1' do |phone_no|
		# send out coon story
		img = 'https://s3.amazonaws.com/st-messenger/day1/floating_shoe/floating_shoe1.jpg'
		"sending first image..."

		# the new way to do it:
		send phone_no, img, 'mms'

		delay phone_no, 'image2', MMS_WAIT
	end

	# No button on the first day! 
	sequence 'image2' do |phone_no|
		# one more button
		puts "sending second image..."
		img = 'https://s3.amazonaws.com/st-messenger/day1/floating_shoe/floating_shoe2.jpg'

		# the new way to do it:
		send phone_no, img, 'mms'

		delay phone_no, 'goodbye', MMS_WAIT
	end

	sequence 'goodbye' do |phone_no|
		puts "saying goodbye..."

		txt = 'scripts.buttons.window_text'

		# the new way to do it:
		send phone_no, txt, 'sms'
	end
end 

