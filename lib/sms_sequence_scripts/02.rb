Birdv::DSL::ScriptClient.new_script 'day2', 'sms' do

	sequence 'firstmessage' do |phone_no|
		txt = 'scripts.first_book.__poc__'
		puts "sending intro txt..."
		send_sms phone_no, txt, 'firstmessage', 'image1'
	end

	sequence 'image1' do |phone_no|
		img = 'mms.stories.hero[0]'
		puts "sending first image..."
		send_mms phone_no, img, 'image1', 'image2'
	end

	sequence 'image2' do |phone_no|
		# one more button
		puts "sending second image..."
		img = 'mms.stories.hero[1]'
		send_mms phone_no, img, 'image2', 'feature-phones'

	end


	sequence 'feature-phones' do |phone_no|
		puts "feature phone message..."
		txt = 'feature.messages.opt-in.intro'
		send_sms phone_no, txt, 'feature-phones'
	end
end 

