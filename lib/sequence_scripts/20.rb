Birdv::DSL::ScriptClient.new_script 'day20' do


  button_story({
    name:     'tap_here',
    title:    'scripts.buttons.title[0]',
    image_url:  '*https://s3.amazonaws.com/st-messenger/day1/bird2/bird2-button.jpg',
    buttons:  [postback_button('scripts.buttons.tap', script_payload(:storysequence))]
  })

  sequence 'greeting' do |recipient|
    txt = 'scripts.intro.__poc__[3]'
    send recipient, text({text: txt})
    delay recipient, 'storybutton', 3.seconds
  end

  sequence 'storybutton' do |recipient|   
    # send tap_here button
    send recipient, button({name:'tap_here'})
  end

  sequence 'storysequence' do |recipient|
    
    # send out story
    send recipient, story({story: 'bird2'})

    # delay 'thanks'
    delay recipient, 'thanks', 23.seconds
  end

  sequence 'thanks' do |recipient|
    txt = 'scripts.outro.__poc__[0]'
    send recipient, text({text:txt})
  end

  sequence 'yourwelcome' do |recipient|
    send recipient, text({text:'scripts.buttons.welcome'})
  end
end 