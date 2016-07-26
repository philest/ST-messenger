Birdv::DSL::ScriptClient.new_script 'day1', 'mms' do

	day 1

	SMS_WAIT = 10.seconds
	MMS_WAIT = 20.seconds

	# recipients are phone numbers
	sequence 'firstmessage' do |phone_no|
		txt = "scripts.teacher_intro"
		puts "sending sms with txt = #{txt}"
		send_sms phone_no, txt

		puts "delaying for #{SMS_WAIT}"
		# delay the conventional SMS delay
		delay phone_no, 'image1', SMS_WAIT
	end


	sequence 'image1' do |phone_no|
		# send out coon story
		img = 'https://s3.amazonaws.com/st-messenger/day1/floating_shoe/floating_shoe1.jpg'
		"sending img..."
		send_mms phone_no, img

		delay phone_no, 'image2', MMS_WAIT
	end

	# No button on the first day! 
	sequence 'image2' do |phone_no|
		# one more button
		puts "sending second image..."
		txt = 'scripts.buttons.window_text'
		send_sms phone_no, txt

	end
end 

