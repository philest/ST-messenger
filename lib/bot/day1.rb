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
								[
									"Read my first story!",
								  ""
								],
								[
									"Message my teacher?",
								  "Just type a message, and Ms. Stobierski will see it next time she’s on her computer :)"	
								],
								[
									"When does it come?",
								  "You’ll get a StoryTime Facebook message each night at 7pm :)"
								]
						  ]

# e.g. of payload format:
# '3_x_x' = story 3, garbage, garbage
BTN_GROUP2 = [

						 ]

# e.g. of payload format:
# '3_1_2' = btn_group 3, button 1, binarystring 2
def button_json(title, btn_group, bin)
	return {
  	type:   'postback',
  	title:  "#{title}",
  	payload:"#{btn_group}_#{bin}" 
	}
end

=begin
def select_btn (btn_group, bin)
	arr_size = btn_group.size
	reversed_bin_str = ("%0#{arr.size}b" % 3).reverse

	selected_btns = eval("BTN_GROUP#{btn_group}").select.with_index do |e, i|
		reversed_bin_str[i] == "1"
	end
	return selected_btns
end
=end

def generate_buttons(recipient, btn_group, message_text, bin)
	arr_size = btn_group.size
	reversed_bin_str = ("%0#{arr_size}b" % bin).reverse

	selected_btns = eval("BTN_GROUP#{btn_group}").map.with_index do |e, i|
		if (reversed_bin_str[i] == "1")
			[e,(2**i)]
		else
			""
		end
	end

	formated_buttons = selected_btns.reject{ |c| c.empty? }.map do |e|
		button_json(e[0],btn_group,bin-e[1])
	end

	btn_rqst= { recipient: {id: recipient},
							message: {
								attachment: {
									type: 'template',
									payload: {
										template_type:'button',
										text: message_text,
										buttons: formated_buttons
									}
								}
							}
						}

	return btn_rqst
end

def day1(recipient, payload)
	btn_group, btn_num, btn_bin = payload.split('_')

	case 

end