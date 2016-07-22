Birdv::DSL::ScriptClient.new_script 'day1' do

	day 1

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
		buttons: 	[postback_button('scripts.buttons.tap', script_payload(:greeting))]
	})

	button_normal({
		name: 			 'thanks',
		window_text: 'scripts.buttons.window_text',
		buttons: 			[postback_button('scripts.buttons.thanks', script_payload(:yourwelcome))]
	})

	sequence 'firsttap' do |recipient|
		# no longer a text before.
		# send tap_here button
		send recipient, button({name:'tap_here'}) 
	end

	sequence 'greeting' do |recipient|
		# greeting with 5 second delay
		txt = 'scripts.teacher_intro'
		send recipient, text({text:txt})

		delay recipient, 'storysequence', 4.2.seconds
	end

	sequence 'storysequence' do |recipient|

		# send out coon story
		send recipient, story()

		delay recipient, 'thanks', 23.seconds

	end

	# No button on the first day! 
	sequence 'thanks' do |recipient|
		txt = 'scripts.buttons.window_text'
		send recipient, text({text:txt})
	end

	sequence 'yourwelcome' do |recipient|
		send recipient, text({text:'scripts.buttons.welcome'}) 
	end
end 

