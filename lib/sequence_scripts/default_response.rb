Birdv::DSL::StoryTimeScript.new 'defaultresponse' do
	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#


	button_normal({
		name: 			 'teacher_response',
		window_text: "Hi, this is StoryTime! We'll see your message soon. To send your text to __TEACHER__, tap 'send'.",
		buttons: 			[postback_button('Thank you!', script_payload(:teachersend))]
	})


	sequence 'usermessage' do |recipient|
		txt = "Hi __PARENT__! I'm away now, but I'll see your message soon. If you need help just enter 'help.'"
		send recipient, text({text:txt})
	end

end 