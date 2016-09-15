Birdv::DSL::ScriptClient.new_script 'day1' do

	# NOTE:
	# EVERY STORY MUST HAVE:
	# 1) storybutton
	# 2) storysequence


	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	button_story({
		name: 		'tap_here',
		title: 		'scripts.buttons.title',
		image_url:  'scripts.buttons.story_img_url', 
		buttons: 	[postback_button('scripts.buttons.tap', script_payload(:storysequence))]
	})

	sequence 'greeting' do |recipient|
		# greeting with 5 second delay
		txt = 'scripts.teacher_intro'
		send recipient, text({text:txt})
		delay recipient, 'storysequence', 3.5.seconds
	end

	sequence 'storysequence' do |recipient|
		send recipient, story()
		delay recipient, 'thanks', 23.seconds
	end

	# No button on the first day! 
	sequence 'thanks' do |recipient|
		# one more button
		txt = 'scripts.buttons.window_text[0]'
		send recipient, text({text:txt})	

	end

	# optional sequence to include a day1 button! 
	sequence 'storybutton' do |recipient|
		# send tap_here button
		send recipient, button({name:'tap_here'}) 
	end

end 

