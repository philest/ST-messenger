Birdv::DSL::ScriptClient.new_script 'day6' do

	day 6
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

	button_normal({
		name: 			 'thanks',
		window_text: 'scripts.buttons.window_text',
		buttons: 			[postback_button('scripts.buttons.thanks', script_payload(:yourwelcome))]
	})

	sequence 'firsttap' do |recipient|
		# greeting with 4 second delay
		txt = 'scripts.teacher_intro'
		send recipient, text({text:txt}),  4 
		
		# send tap_here button
		send recipient, button({name:'tap_here'})
	end

	sequence 'storysequence' do |recipient|
		
		# send out story
		send recipient, story(), 23

		# delay 'thanks'
		delay recipient, 'thanks', 23.seconds
	end

	sequence 'thanks' do |recipient|
		# one more button
		send recipient, button({name:'thanks'})
	end

	sequence 'yourwelcome' do |recipient|
		send recipient, text({text:'scripts.buttons.welcome'})
	end
end 