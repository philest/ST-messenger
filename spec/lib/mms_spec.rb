# testing is useful to simulate behavior an uncover blatant bugs.
# overtesting is just wasteful.

describe 'mms' do
	context 'StoryTimeScript#translate_mms' do
		context 'name codes' do
			it 'finds a user if they have a facebook id but no phone'

			it 'finds a user if they have a phone but no facebook id'

			it 'returns the correct string'
		end
		it 'translates text correctly'
	end

	context 'ScheduleWorker' do
		it 'calls perform_async on StartDayWorker with the correct platform arguments'

		it 'filters the right people'
	end

	context 'mms scripts' do
		it 'registers sequences properly'

		it 'makes me proud'

		it 'cowers before the Lord'

		it 'powers the megalopolips EcoEngine'

		it 'brings me to the ass kingdom'

		it 'sends mms to the correct URLS'
	end

	context 'when users register with facebook' do 
		it 'registers them with a fb_id but without a phone number'

		it 'gives users the benefit of the doubt'

		it ''
	end

	context 'when sending mms' do
		it 'checks to see if the POST request failed and does something about it'

	end

end