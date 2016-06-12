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
            url: 'http://s33.postimg.org/z2io2l1gv/floating_Shoe1.jpg'
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
            url: 'http://s33.postimg.org/487qtv4bz/floating_Shoe2.jpg'
          }
        }
		}
	)
end


