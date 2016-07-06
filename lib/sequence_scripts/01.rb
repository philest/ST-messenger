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
									"It's __TEACHER__ again. I’ll send another storybook tomorrow :)",
									[
										postback_button('Thank you!', script_payload(:yourwelcome))
									])


	sequence 'firsttap' do |recipient|
		# no longer a text before.
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'coonstory' do |recipient|
		# greeting with 4 second delay
		txt = "Hi __PARENT__, this is __TEACHER__. Here's your first free book on StoryTime!"
		send text(txt), recipient, 5.35 

		# send out coon story
		img_1 = "https://s3.amazonaws.com/st-messenger/day1/tap_and_swipe.jpg"
		send picture(img_1), recipient

		version = get_curriculum_version(recipient)
		story = CURRICULUM[version][0][:name]
		num_pages = CURRICULUM[version][0][:pages]

		send_story 'day1', story, num_pages, recipient

		img_2 = "https://s3.amazonaws.com/st-messenger/day1/go_up.jpg"
		send picture(img_2), recipient, 23

		# one more button
		send button('thanks'), recipient
	end

	sequence 'yourwelcome' do |recipient|
		send text("You're welcome :)"), recipient
	end
end 