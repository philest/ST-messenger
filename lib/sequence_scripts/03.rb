Birdv::DSL::StoryTimeScript.new 'day3' do


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
		send text(txt), recipient, 4 
		
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'scratchstory' do |recipient|
		# send out cook story

		send_story 'day1', 'scratch', 6, recipient
		img_1 = "https://s3.amazonaws.com/st-messenger/day1/scroll_up.jpg"
		send picture(img_1), recipient, 23

		# one more button
		send button('thanks'), recipient
	end

	sequence 'yourwelcome' do |recipient|
		send text("You're welcome :)"), recipient
	end
end 