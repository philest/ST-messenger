Birdv::DSL::ScriptClient.new_script 'day4' do
	# day 4
	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	button_story({
		name: 		'tap_here',
		title: 		'scripts.buttons.title[0]',
		image_url:  'scripts.buttons.tap_here', 
		buttons: 	[postback_button('scripts.buttons.tap', script_payload(:storysequence))]
	})


	sequence 'greeting' do |recipient|
		txt = 'scripts.intro.__poc__[3]'
		send recipient, text({text: txt})
		delay recipient, 'storybutton', 3.seconds
	end

	sequence 'storybutton' do |recipient|		
		# send tap_here button
		send recipient, button({name:'tap_here'})
	end

	sequence 'storysequence' do |recipient|
		# send out cook story
		send recipient, story()
	
		# one more button
		delay recipient, 'thanks', 23.seconds 
	end

	sequence 'thanks' do |recipient|
		# one more button
		# send recipient, button({name:'thanks'})
		txt = 'scripts.outro.__poc__[3]'
		send recipient, text({text:txt})
	end

	sequence 'yourwelcome' do |recipient|
		send recipient, text({text:'scripts.buttons.welcome'})
	end
end 