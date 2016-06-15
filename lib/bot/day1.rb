require 'json'
stories = [
					 "clouds":2,
					 "floating_shoe":2,
					 "hero":2
					]

# e.g. of payload format:
# '3_1_2' = btn_group 3, button 1, binarystring 2
BTN_GROUP0 = [
							"Tap here!",
						 ]

BTN_GROUP1 =  [		
							 "Thank you!"		
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
	# if btn_bin==0 
	# 	return
	# end

	tname = fb_get_name_honorific(recipient['id'])

	case btn_group

	#
	# btn group #0
	#	
	when 0 # the behaviour of btn group 0 is different :P
		case btn_bin
		when 0
			fb_send_pic(recipient,"https://s3.amazonaws.com/st-messenger/day1/tap_and_swipe.jpg")
			send_story(recipient, 'day1', 'cook', 8)
			delay_after 15, fb_send_pic(recipient,"https://s3.amazonaws.com/st-messenger/day1/scroll_up.jpg")
			fb_send_arbitrary(generate_btns(recipient, 1, 'Ms. Stobierski: I’ll send another storybook tomorrow :) Just reply to send me a message.',7))		
		else	
			btn = btn_json('Tap here!', 0, 0, 0)
			delay_after 4, fb_send_txt(recipient, "Hi Ms. Edwards, this is Ms. Stobierski. I’ve signed our class up to get free nightly books here on StoryTime.")
			fb_send_template_generic(recipient, 'Tap below', "https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg", [btn])
		end
		
		
	#
	# btn group #1
	#		
	when 1
		fb_send_txt(recipient,"You're welcome :).")

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
