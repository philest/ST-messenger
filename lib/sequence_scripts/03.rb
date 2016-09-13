Birdv::DSL::ScriptClient.new_script 'day3' do

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
		txt = 'scripts.teacher_intro'
		send recipient, text({text: txt})
		delay recipient, 'storysequence', 3.5.seconds
	end

	sequence 'storysequence' do |recipient|
		send recipient, story()		
		delay recipient, 'thanks', 23.seconds
	end

	sequence 'thanks' do |recipient|
		txt = 'scripts.buttons.window_text[2]'
		send recipient, text({text:txt})	
	end

	sequence 'yourwelcome' do |recipient|
		send recipient, text({text:'scripts.buttons.welcome'})
	end
end 