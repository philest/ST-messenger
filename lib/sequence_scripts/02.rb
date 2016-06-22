Birdv::DSL::StoryTimeScript.new 'day2' do


	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	story_button( 'tap_here', 
								"Let's get tonight's story.", 
								'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
								[
									postback_button('Tap here!', script_payload(:cookstory))
								])

	button_normal( 'thanks',
									'Ms. Stobierski: I’ll send another story tomorrow night. You both are doing great! :)',
									[
										postback_button('Thank you!', script_payload(:yourwelcome))
									])


	sequence 'firsttap' do |recipient|
		# greeting with 4 second delay
		txt = "Ms Stobierski: Hi Ms. Edwards, here’s /
			   another story to prepare Calivin for kindergarten."
		send text(txt), recipient, 4 
		
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'cookstory' do |recipient|
		# send out cook story
		send_story 'day1', 'cook', 11, recipient, 15
		

		# one more button
		send button('thanks'), recipient
	end

	sequence 'yourwelcome' do |recipient|
		send text("You're welcome :)"), recipient
	end
end 