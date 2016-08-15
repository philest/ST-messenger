require 'spec_helper'
require 'bot/dsl'

# testing is useful to simulate behavior and uncover blatant bugs.
# overtesting is just wasteful.

describe 'mms' do
  context 'StoryTimeScript#translate_sms', mms:true do
    context 'name codes' do
      it 'translates shit' do
        @s = Birdv::DSL::StoryTimeScript.new 'day1', 'sms' do; end

        user = User.create phone: '8186897323'
        @s.name_codes "hi there", '8186897323'


      end
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


    it 'sends mms to the correct URLS'
  end

  context 'when users register with facebook' do 
    it 'registers them with a fb_id but without a phone number'

  end

  context 'when sending mms' do
    it 'checks to see if the POST request failed and does something about it'

    it 'sends a POST request to the correct URLs in st-enroll'






  end

end






