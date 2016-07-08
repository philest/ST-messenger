Birdv::DSL::StoryTimeScript.new 'day3' do

	day 3


	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	button_story({
		name: 		'tap_here',
		title: 		"You're next story's coming soon!",
		image_url:'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
		buttons: 	[postback_button('Tap here!', script_payload(:scratchstory))]
	})


	button_normal({
		name: 			 'thanks',
		window_text: "__TEACHER__: I’ll send another story tomorrow night :)",
		buttons: 			[postback_button('Thank you!', script_payload(:yourwelcome))]
	})

	sequence 'firsttap' do |recipient|
		# greeting with 4 second delay
		txt = "__TEACHER__: Hi __PARENT__, here’s another story!"
		send recipient, text({text:txt}),  4 
		
		# send tap_here button
		send recipient, button({name:'tap_here'})
	end

	sequence 'scratchstory' do |recipient|
		# send out cook story

		send recipient, story()
		
		img_1 = "https://s3.amazonaws.com/st-messenger/day1/scroll_up.jpg"
		send recipient, picture({url:img_1}), 23

		# one more button
		send recipient, button('thanks') 
	end

	sequence 'yourwelcome' do |recipient|
		send recipient, text({text:"You're welcome :)"})
	end
end 