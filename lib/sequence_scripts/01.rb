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
									postback_button('Tap here!', script_payload(:coonstory))
								])

	button_normal( 'thanks',
									'Ms. Stobierski: I’ll send another storybook tomorrow :) Just reply to send me a message.',
									[
										postback_button('Thank you!', script_payload(:yourwelcome))
									])


	sequence 'firsttap' do |recipient|
		# greeting with 4 second delay
		txt = "Hi Ms. Edwards, this is Ms. Stobierski. I’m sending you and Calvin free nightly books here on StoryTime!"
		send text(txt), recipient, 4.75 
		
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'coonstory' do |recipient|
		# send out cook story
		img_1 = "https://s3.amazonaws.com/st-messenger/day1/tap_and_swipe.jpg"
		send picture(img_1), recipient
<<<<<<< HEAD
		send_story 'day1', 'coon', 9, recipient, 15
=======
		send_story 'day1', 'coon', 8, recipient

		img_2 = "https://s3.amazonaws.com/st-messenger/day1/go_up.jpg"
		send picture(img_2), recipient, 23
>>>>>>> 087b9fd450d635d5764cdd5abcc6565ddb7dc262
		

		# one more button
		send button('thanks'), recipient
	end

	sequence 'yourwelcome' do |recipient|
		send text("You're welcome :)"), recipient
	end
end 