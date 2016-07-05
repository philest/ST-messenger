Birdv::DSL::StoryTimeScript.new 'day1' do

	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	story_button( 'tap_here', 
								"Let's read your first story.", 
								'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
								[
									postback_button('Tap here!', script_payload(:birdstory))
								])

	button_normal( 'thanks',
									"It's __TEACHER__ again. I’ll send another storybook tomorrow :)",
									[
										postback_button('Thank you!', script_payload(:yourwelcome))
									])


	sequence 'firsttap' do |recipient|
		# no longer a text before.
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'birdstory' do |recipient|
		# greeting with 4 second delay
		txt = "Hi __PARENT__, this is __TEACHER__. Here's your first free book on StoryTime!"
		send text(txt), recipient, 5.15 

		# send out bird story
		img_1 = "https://s3.amazonaws.com/st-messenger/day1/bird/bird-tap-final.jpg"
		send picture(img_1), recipient
		img_2 = "https://s3.amazonaws.com/st-messenger/day1/bird/bird-title.jpg"
		send picture(img_2), recipient
		send_story 'day1', 'bird', 8, recipient, 23

		# one more button
		send button('thanks'), recipient
	end

	sequence 'yourwelcome' do |recipient|
		send text("You're welcome :)"), recipient
	end
end 