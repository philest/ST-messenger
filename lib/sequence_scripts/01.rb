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
		title: 		"Let's read tonight's story.",
		image_url:'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
		buttons: 	[postback_button('Tap here!', script_payload(:coonstory))]
	})


	button_normal({
		name: 			 'thanks',
		window_text: "__TEACHER__: I’ll send another story tomorrow night. You both are doing great! :)",
		buttons: 			[postback_button('Thank you!', script_payload(:yourwelcome))]
	})


	sequence 'firsttap' do |recipient|
		# no longer a text before.
		# send tap_here button
		send recipient, button({name:'tap_here'}) 
	end

	sequence 'coonstory' do |recipient|
		# greeting with 4 second delay
		txt = "Hi __PARENT__, this is __TEACHER__. Here's your first free book on StoryTime!"
		send recipient, text({text:txt}), 5.35 

		# send out coon story
		send recipient, story(), 23 

		# one more button
		send recipient, button({name:'thanks'})
	end

	sequence 'yourwelcome' do |recipient|
		send recipient, text({text:"You're welcome :)"}) 
	end
end 






