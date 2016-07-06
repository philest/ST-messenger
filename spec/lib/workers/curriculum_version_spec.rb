require 'spec_helper'
require 'timecop'
require 'active_support/time'
require 'workers/bot_worker'
require 'bot/dsl'

describe "curriculum versions" do

	let (:user1) { User.create }
	let (:user2) { User.create(story_number: 2) }

	context "" do

	end



end