Birdv::DSL::StoryTimeScript.new 'defaultresponse' do
	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#


	sequence 'usermessage' do |recipient|
		send text("Hi __PARENT__! I'm away now, but I'll see your message soon. If you need help just enter 'help.'"), recipient
	end

end 