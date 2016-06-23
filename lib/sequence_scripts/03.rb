Birdv::DSL::StoryTimeScript.new 'day3' do


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
									postback_button('Tap here!', script_payload(:scratchstory))
								])

	button_normal( 'thanks',
									'Ms. Stobierski: I’ll send another story tomorrow night :)',
									[
										postback_button('Thank you!', script_payload(:yourwelcome))
									])


	sequence 'firsttap' do |recipient|
		# greeting with 4 second delay
		txt = "Ms Stobierski: Hi Ms. Edwards, here’s /
			   another story!"
		send text(txt), recipient, 4 
		
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'scratchstory' do |recipient|
		# send out cook story
		send_story 'day1', 'scratch', 6, recipient, 15
		

		# one more button
		send button('thanks'), recipient
	end

	sequence 'yourwelcome' do |recipient|
		send text("You're welcome :)"), recipient
	end
end 