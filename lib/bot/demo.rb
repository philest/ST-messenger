def demo(message)
  Bot.deliver(
		recipient: message.sender,
		message: {
			text: "Here's your story!"
		}
	)
	Bot.deliver(
		recipient: message.sender,
		message: {
			attachment: {
          type: 'image',
          payload: {
          	# floating shoe 1
            url: 'https://s3.amazonaws.com/st-messenger/day1/floating_shoe/floating_shoe1.jpg'
          }
        }
		}
	)
	Bot.deliver(
		recipient: message.sender,
		message: {
			attachment: {
          type: 'image',
          payload: {
          	# floating shoe 2
            url: 'https://s3.amazonaws.com/st-messenger/day1/floating_shoe/floating_shoe1.jpg'
          }
        }
		}
	)
end


