Birdv::DSL::ScriptClient.new 'help' do
	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#

	sequence 'helpstart' do |recipient|
		txt = "Hi, this is StoryTime! We help your teacher send free nightly stories.\n\n - To stop, reply ‘stop’\n - For help, try 561-212-5831"
		send recipient, text({text:txt}) 
	end

end 