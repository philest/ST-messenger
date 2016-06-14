require 'json'
stories = [
					 "clouds":2,
					 "floating_shoe":2,
					 "hero":2
					]

# e.g. of payload format:
# '3_1_2' = btn_group 3, button 1, binarystring 2
BTN_GROUP0 = [
							"Read my first story!",
							"What is StoryTime?"
						 ]

BTN_GROUP1 =  [		
							 "Read my first story!",		
							 "Message my teacher?",		
							 "When does it come?"			
						  ]

# e.g. of payload format:
# '3_x_x' = story 3, garbage, garbage
BTN_GROUP2 = [
							"Read it!"
						 ]

BTN_GROUP3 = [
							"Read it!"
						 ]			

BTN_GROUP4 =  [		
							 "What is StoryTime?",
							 "Thank you!"
						  ]



# delay the message after sending--will need to make this different later
def delay_after(secs, f)
	#todo, should check if f when ok
	sleep secs
end


def day1(recipient, payload)
	
	# parse payload
	btn_group, btn_num, btn_bin = payload.split('_').map { |e| e.to_i }
	if btn_bin==0 
		return
	end

	tname = fb_get_name_honorific(recipient['id'])

	case btn_group

	#
	# btn group #0
	#	
	when 0 # the behaviour of btn group 0 is different :P

		formatted_buttons = format_buttons(0,3)
		turl= 'https://s3.amazonaws.com/st-messenger/day1/clouds/cloudstitle.jpg'
		case btn_num
		when 3 # when request a dayone demo
			greeting = tname.empty? ? "Hi" : "Hi #{tname}"
			delay_after 2, 		fb_send_txt(recipient, "#{greeting}, this is Ms. Stobierski from the YMCA!")
			delay_after 3, 		fb_send_txt(recipient, "I’ve signed our class up to get free nightly stories on StoryTime, starting tonight!")
			fb_send_template_generic(recipient, 'Welcome to StoryTime!', turl, formatted_buttons)

		when 0 # read first story
			delay_after 1.75, 	fb_send_pic(recipient, "https://s3.amazonaws.com/st-messenger/day1/sammy_bird.png")
			
			delay_after 3, 	fb_send_txt(recipient, 'Great! I’m Sammy, the StoryTime Bird! Ms. Stobierski asked me to bring you your first story :)')			
			delay_after 4.4, fb_send_txt(recipient, "Here it comes! Tap the first picture to make it big, then swipe to read through!")
			delay_after 12, 	send_story(recipient, 'day1', 'clouds', 2)
			delay_after 1.25, fb_send_txt(recipient,"When you’re done reading your first story, here's another :)")
			story_btn(recipient, 'day1', "The Shoe Boat", "floating_shoe", 2)

		when 1 # what is ST?
			delay_after 1.1, fb_send_txt(recipient,"StoryTime is a free program that Ms. Stobierski is using to send nightly stories by Facebook :)")
			fb_send_arbitrary(generate_buttons(recipient,1,"Do you have any other questions?",7))
		else
			fb_send_template_generic(recipient, 'Welcome to StoryTime!', '', formatted_buttons) # no picture needed
		end
	
	#
	# btn group #1
	#		
	when 1
		case btn_num

		when 0 # same same btn_group 0, btn 0
			delay_after 1.75, 	fb_send_pic(recipient, "https://s3.amazonaws.com/st-messenger/day1/sammy_bird.png")
			
			delay_after 3, 	fb_send_txt(recipient, 'Great! I’m Sammy, the StoryTime Bird! Ms. Stobierski asked me to bring you your first story :)')			
			delay_after 4.4, fb_send_txt(recipient, "Here it comes! Tap the first picture to make it big, then swipe to read through!")
			delay_after 12, 	send_story(recipient, 'day1', 'clouds', 2)
			delay_after 1.25, fb_send_txt(recipient,"When you’re done reading your first story, here's another :)")
			story_btn(recipient, 'day1', "The Shoe Boat", "floating_shoe", 2)
		when 1
			delay_after 1.1, fb_send_txt(recipient, "Just type a message, and Ms. Stobierski will see it next time she’s on her computer :)")
			fb_send_arbitrary(generate_buttons(recipient,1,"Do you have any other questions?",btn_bin))
		when 2
			delay_after 0.7, fb_send_txt(recipient, "You’ll get a StoryTime Facebook message each night at 7pm :)")
			fb_send_arbitrary(generate_buttons(recipient,1,"Do you have any other questions?",btn_bin))
		end
	
	#
	# btn group #2 (the floating shoe!)
	#	
	when 2 
			delay_after 2, fb_send_txt(recipient, "I promised Ms. Stobierski I’d bring you the best stories I could find :)")
			delay_after 15, 	send_story(recipient, 'day1',  "floating_shoe", 2)
			delay_after 1.75, fb_send_txt(recipient, "Every night, I’ll bring your new stories in a Facebook message.")
			delay_after 1, 		fb_send_txt(recipient, "Then, you can read together on your phone :) ")
			delay_after 1.25, fb_send_txt(recipient, "Here’s tonight’s last story!")
			story_btn(recipient, 'day1', "My Super Power!", "hero", 3)

	
	when 3
			delay_after 2, fb_send_txt(recipient, "This one’s my favorite :)")
			delay_after 9, 		send_story(recipient, 'day1', "hero", 2)

			greeting = tname.empty? ? "Thanks" : "Thanks, #{tname}"
			fb_send_arbitrary(generate_buttons(recipient,4,"Ms. Stobierski: #{greeting}! I’ll send more stories tomorrow night. Reply to send me a message.",3))
	
	when 4

		case btn_num
		when 0
			delay_after 1.1, fb_send_txt(recipient,"StoryTime is a free program that Ms. Stobierski is using to send nightly stories by Facebook :)")
			fb_send_arbitrary(generate_buttons(recipient,1,"Do you have any other questions? ",6))
		else
			fb_send_txt(recipient, "You're welcome :)")
		end
	end
end

=begin
			welcm_url= 'https://s3.amazonaws.com/st-messenger/day1/clouds/clouds1.jpg?X-Amz-Date=20160613T000136Z&X-Amz-Expires=300&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=7cd837eeb1c91c111c2ab3cd0441b436a3682b0fbda6adf8dc0d32e4e9488161&X-Amz-Credential=ASIAI6RXFEDGTLQDKLSQ/20160613/us-east-1/s3/aws4_request&X-Amz-SignedHeaders=Host&x-amz-security-token=FQoDYXdzEE8aDBsjw2fCKn9tcL9NnCLHATYpb2PfFPUepiG0c7nyh2HOHIPweqnYHUqMqj414121/Ko4aM%2BtGQuVNDbAC8zu1g7b8oe8Hatb1iAurKhUV3h/NG3mHbBUQoKJ0O3dAhgac8suVxQXp67BtGAiQgAhJSq31OnWluLPCTG4I6G96AL0M5jdQqTdvVB4oZfZermR/3d2sYSuBw%2Bb6MNYH0nUUcXLpkT1DPEoJdTsPhvHppjM5hTtZ9wp2mB2nFTn3rMlp8i/GhAeMYib3MPIR0hY0dYTsdSIsQko6rz3ugU%3D'
			formatted_buttons = format_buttons(0, 3)


		    blah = {recipient: "10209571935726081",
		      message: {
		        attachment: {
		          type:'template',
		          payload:{
		            template_type: 'generic',
		            elements: [
		              {   
		                title: "hey",
		                image_url: welcm_url,
		                buttons:formatted_buttons
		              }
		            ]
		          }
		        }
		      }}

		      puts JSON.pretty_generate(blah)
=end
