Birdv::DSL::StoryTimeScript.new 'day2' do

	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#

	sequence 'first_tap' do |recipient|
		# greeting with 4 second delay
		txt = "So this should happen periodically!"
		send text(txt), recipient, 4 
	end

end 