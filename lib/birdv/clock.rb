require "clockwork"
require './worker'

module Clockwork
  every 20.seconds, 'send.stories' do 
  	StoryWorker.perform_async
  end
end
