Birdv::DSL::StoryTimeScript.new 'help' do
	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#


	sequence 'help_start' do |recipient|
		send text("Hi, this is StoryTime! We help your teacher send free nightly stories.\n\n - To stop, reply ‘stop’\n - For help, try 561-212-5831"), recipient
	end

end 