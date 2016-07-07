Birdv::DSL::StoryTimeScript.new 'day2' do

	day 2


	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#

	button_story({
		name: 		'tap_here',
		title: 		"Let's read tonight's story.",
		image_url:'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
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
		send text(txt), recipient, 4 
		
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'cookstory' do |recipient|
		# send out cook story

		send_story recipient, 23
		
		# one more button
		send button('thanks'), recipient
	end

	sequence 'yourwelcome' do |recipient|
		send text("You're welcome :)"), recipient
	end
end 