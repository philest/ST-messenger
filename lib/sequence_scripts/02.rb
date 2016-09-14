Birdv::DSL::ScriptClient.new_script 'day2' do

	# day 2


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

	# sequence 'firsttap' do |recipient|
	# 	# greeting with 4 second delay
	# 	txt = 'scripts.teacher_intro'
	# 	send recipient, text({text: txt})
		
	# 	# send tap_here button
	# 	send recipient, button({name:'tap_here'})
	# end

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
		txt = 'scripts.buttons.window_text[1]'
		send recipient, text({text:txt})	
	end

	sequence 'yourwelcome' do |recipient|
		send recipient, text({text:'scripts.buttons.welcome'}) 
	end


	# optional sequence to include a day1 button! 
	sequence 'storybutton' do |recipient|
		# send tap_here button
		send recipient, button({name:'tap_here'}) 
	end

end 












