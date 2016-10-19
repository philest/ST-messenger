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
		title: 		'scripts.buttons.title[0]',
		image_url:  'scripts.buttons.story_img_url', 
		buttons: 	[postback_button('scripts.buttons.tap', script_payload(:storysequence))]
	})

	sequence 'greeting' do |recipient|
		txt = 'scripts.teacher_intro[0]'

		txt = msging('scripts.intro.__poc__[0]')
		send recipient, text({text:txt})
		delay recipient, 'storysequence', 3.5.seconds
	end

	sequence 'storysequence' do |recipient|
		send recipient, story()
		delay recipient, 'thanks', 23.seconds
	end

	sequence 'thanks' do |recipient|
		# one more button
		txt = 'scripts.buttons.window_text[0]'
		send recipient, text({text:txt})	
	end

	sequence 'code' do |recipient|
		url = 'https://s3.amazonaws.com/st-messenger/day1/twilio-mms-child.jpg'
		send recipient, picture({url: url})
	
		txt = 'scripts.code.enter_code'
		send recipient, text({text:txt})
	end

	# optional sequence to include a day1 button! 
	sequence 'storybutton' do |recipient|
		send recipient, button({name:'tap_here'}) 
	end

end 

