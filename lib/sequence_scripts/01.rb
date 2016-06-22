Birdv::DSL::StoryTimeScript.new 'day1' do

	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	story_button( 'tap_here', 
								'(not here)', 
								'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
								[
									postback_button('Tap here!', script_payload(:cookstory))
								])

	button_normal( 'thanks',
									'Ms. Stobierski: I’ll send another storybook tomorrow :) Just reply to send me a message.',
									[
										postback_button('Thank you!', script_payload(:yourwelcome))
									])


	sequence 'firsttap' do |recipient|
		# greeting with 4 second delay
		txt = "Hi Ms. Edwards, this is Ms. Stobierski. I’ve signed our class up to get free nightly books here on StoryTime."
		send text(txt), recipient, 4 
		
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'cookstory' do |recipient|
		# send out cook story
		img = "https://s3.amazonaws.com/st-messenger/day1/tap_and_swipe.jpg"
		send picture(img), recipient
		send_story 'day1', 'cook', 10, recipient, 15

		# one more button
		send button('thanks'), recipient
	end

	sequence 'yourwelcome' do |recipient|
		send text("No, no. Thank YOU!"), recipient
	end
end 