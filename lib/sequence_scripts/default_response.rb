Birdv::DSL::StoryTimeScript.new 'defaultresponse' do
	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	button_normal( 'teacher_response',
									"Hi, this is StoryTime! We'll see your message soon. To send your text to __TEACHER__, tap 'send'.",
									[
										postback_button('Send', script_payload(:teachersend))
									])

	sequence 'usermessage' do |recipient|
		send button('teacher_response'), recipient
	end

	sequence 'teachersend' do |recipient|
		send text("Great, they'll see it soon :)"), recipient
	end



end 