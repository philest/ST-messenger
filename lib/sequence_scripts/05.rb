Birdv::DSL::StoryTimeScript.new 'day5' do


	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	story_button( 'tap_here', 
								"Your next story's on the way.", 
								'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
								[
									postback_button('Read it!', script_payload(:birdstory))
								])

	button_normal( 'thanks',
									"I’ll send another story tomorrow night :)",
									[
										postback_button('Thank you!', script_payload(:yourwelcome))
									])


	sequence 'firsttap' do |recipient|
		# greeting with 4 second delay
		txt = "Hi __PARENT__, it's __TEACHER__. Here’s another story!"
		send text(txt), recipient, 4 
		
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'birdstory' do |recipient|
		# send out cook story

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