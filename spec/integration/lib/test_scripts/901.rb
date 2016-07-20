Birdv::DSL::ScriptClient.new_script 'day901' do

	day 901


	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#

	button_story({
		name: 		'tap_here',
		title: 		"Let's read tonight's story.",
		image_url:'http://d2p8iyobf0557z.cloudfront.net/day1/tap_here.jpg', 
		buttons: 	[postback_button('Tap here!', script_payload(:cookstory))]
	})


	button_normal({
		name: 			 'thanks',
		window_text: "__TEACHER__: I’ll send another story tomorrow night. You both are doing great! :)",
		buttons: 			[postback_button('Thank you!', script_payload(:yourwelcome))]
	})


	sequence 'firsttap' do |recipient|
		# greeting with 4 second delay
		txt = "Hi __PARENT__, it's __TEACHER__. Here’s another story to get __CHILD__ ready for kindergarten."
		send recipient, text({text: txt}), 4 
		
		# send tap_here button
		send recipient, button({name:'tap_here'})
	end

	sequence 'cookstory' do |recipient|
		# send out cook story

		send recipient, story()

		# delay recipient, 'thanks'
		
	end

	sequence 'thanks' do |recipient|
		# one more button
		send recipient, button({name:'thanks'})
	end

	sequence 'yourwelcome' do |recipient|
		send recipient, text({text:"You're welcome :)"}) 
	end
end 












