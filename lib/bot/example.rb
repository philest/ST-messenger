scrp = StoryTimeScript.new 'day1' do
	reg_button 'Button1' do
		url_btn a, b, classify
		postback_btn a, b, sequence_postback('name of sequence')
	end

	story_button 'strbtn' postback_btn a, b, sequence_postback('name of sequence'), 'storyname'

	sequence 'first_one' do |recipient|

	end


end

scrp.run_sequence(recipient, 'sequence')