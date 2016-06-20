require 'facebook/messenger'
require 'httparty'
require_relative 'dsl'
require 'http_logger'
include Birdv::DSL

ENV['FB_ACCESS_TKN'] = 'EAAYOZCnHw2EUBAD41w1cxfQFTuzzjbpFQ4da1GdtRjmDYhFGTCd3KOIiE5UQIbEUQwVOsFN0Tz7WsyDIFdQf2Nm0j0sA99qZAV5RZCjcFz89S4kZBZCLZA3foj33svFrmJ7yZCZCe3e16xk9jZBZAXa88jRt1yD348EnqYZCZAvHFVTPiwZDZD'

day1 = StoryTimeScript.new 'day1' do

	#
	# register some buttons for reuse!
	# ================================
	# NOTE: always call story_button, template_generic, 
	# and button_normal OUTSIDE of sequence blocks
	#
	story_button( 'tap_here', 
								'(not here)', 
								'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
								[
									postback_button('Tap here!', :cook_story)
								])

	button_normal( 'thanks',
									'Ms. Stobierski: I’ll send another storybook tomorrow :) Just reply to send me a message.',
									[
										postback_button('Thank you!', :your_welcome)
									])


	sequence 'first_tap' do |recipient|
		# greeting with 4 second delay
		txt = "Hi Ms. Edwards, this is Ms. Stobierski. I’ve signed our class up to get free nightly books here on StoryTime."
		send text(txt), recipient, 4 
		
		# send tap_here button
		send button('tap_here'), recipient
	end

	sequence 'cook_story' do |recipient|
		# send out cook story
		img = "https://s3.amazonaws.com/st-messenger/day1/tap_and_swipe.jpg"
		send picture(img), recipient
		send_story 'day1', 'cook', 2, recipient, 15

		# one more button
		send button('thanks'), recipient
	end

	sequence 'your_welcome' do |recipient|
		send text("No, no. Thank YOU!"), recipient
	end
end 

day1.run_sequence('10209571935726081', 'first_tap')
day1.run_sequence('10209571935726081', 'cook_story')
day1.run_sequence('10209571935726081', 'your_welcome')
