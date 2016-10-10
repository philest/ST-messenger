Birdv::DSL::ScriptClient.new_script 'demo', 'fb' do

  # NOTE:
  # EVERY STORY MUST HAVE:
  # 1) storybutton
  # 2) storysequence
  button_story({
    name:     'tap_here_bird',
    title:    "*Just tap below to start!",
    image_url:  'scripts.buttons.tap_here', 
    buttons:  [postback_button('*Tap here!', script_payload(:birdstorysequence))]
  })

  button_story({
    name:     'tap_here_whale',
    title:    "*Just tap below to start!",
    image_url:  "*https://s3.amazonaws.com/st-messenger/day1/whale/whale-button.jpg", 
    buttons:  [postback_button('*Tap here!', script_payload(:whalestorysequence))]
  })

  button_story({
    name:     'tap_here_seed',
    title:    "*Just tap below to start!",
    image_url:  "*https://s3.amazonaws.com/st-messenger/day1/seed/seed-button.jpg", 
    buttons:  [postback_button('*Tap here!', script_payload(:seedstorysequence))]
  })

  button_story({
    name:     'tap_here_chores',
    title:    "*Just tap below to start!",
    image_url:  "*https://s3.amazonaws.com/st-messenger/day1/chores/chores-button.jpg", 
    buttons:  [postback_button('*Tap here!', script_payload(:choresstorysequence))]
  })

  button_story({
    name:     'tap_here_ants',
    title:    "*Just tap below to start!",
    image_url:  "*https://s3.amazonaws.com/st-messenger/day1/ants/ants-button.jpg", 
    buttons:  [postback_button('*Tap here!', script_payload(:antsstorysequence))]
  })

  sequence 'birdgreeting' do |recipient|
    txt = "*Today in class Jasmine told us all about her baby bird, so I wanted to share this story tonight :) -Ms. Wilson"
    send recipient, text({text:txt})
    send recipient, button({name:'tap_here_bird'})
    unsubscribe_demo recipient
  end

  sequence 'birdstorysequence' do |recipient|
    send recipient, story({story: 'demobird'})
    delay recipient, 'seedgreeting', 12.seconds
  end

  sequence 'seedgreeting' do |recipient|
    txt = "*Jasmine and the class watered our garden today! Here’s tonight's story about growing a magic tree. -Ms. Wilson"
    send recipient, text({text:txt})
    send recipient, button({name:'tap_here_seed'})
  end

  sequence 'seedstorysequence' do |recipient|
    send recipient, story({story: 'demoseed'})
    delay recipient, 'outromessage', 10.seconds
  end

  sequence 'outromessage' do |recipient|
    txt = "*Jasmine has been getting a lot stronger at sounding out letters. This reading is really helping. Thank you mom :)"
    send recipient, text({text: txt})
  end

  sequence 'helpmessage' do |recipient|
    txt  = "*Thanks for trying StoryTime! To end this demo, write 'end demo'.\n"
    txt += "For more stories, just reply 'more'"
    send recipient, text({text:txt})
  end

  sequence 'enddemo' do |recipient|
    txt = "*Thanks for trying out StoryTime!"
    send recipient, text({text:txt})
    resubscribe_demo recipient
  end

  # for more stories
  sequence 'whalegreeting' do |recipient|
    txt = "*Here’s tonight’s Storytime story for Jasmine!\n-Ms. Wilson"
    send recipient, text({text:txt})
    send recipient, button({name:'tap_here_whale'})
  end

  sequence 'whalestorysequence' do |recipient|
    send recipient, story({story: 'whale'})
  end

  sequence 'choresgreeting' do |recipient|
    txt = "*Here’s another story!"
    send recipient, text({text:txt})
    send recipient, button({name:'tap_here_chores'})
  end

  sequence 'choresstorysequence' do |recipient|
    send recipient, story({story: 'chores'})
  end

  sequence 'antsgreeting' do |recipient|
    txt = "*Here’s another story!"
    send recipient, text({text:txt})
    send recipient, button({name:'tap_here_ants'})
  end

  sequence 'antsstorysequence' do |recipient|
    send recipient, story({story: 'ants'})
  end

end 

