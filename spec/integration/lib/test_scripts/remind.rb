Birdv::DSL::ScriptClient.new_script 'remind' do
  #
  # register some buttons for reuse!
  # ================================
  # NOTE: always call story_button, template_generic, 
  # and button_normal OUTSIDE of sequence blocks
  #
  button_normal({
    name:        'resubscribe',
    window_text: 'scripts.buttons.unsubscribe_window_text',
    buttons:      [postback_button('scripts.buttons.resubscribe', script_payload(:resubscribe))]
  })

  button_normal({
    name:        'thanks',
    window_text: 'scripts.buttons.window_text',
    buttons:      [postback_button('scripts.buttons.thanks', script_payload(:yourwelcome))]
  })


  # I should handle resubscribing within the sequence, probably...

  sequence 'remind' do |recipient|
    # greeting with 5 second delay
    txt = 'scripts.remind'
    send recipient, text({text:txt})

  end

  sequence 'unsubscribe' do |recipient|

    send recipient, button({name:'resubscribe'})

  end

  sequence 'resubscribe' do |recipient|

    txt = 'scripts.resubscribe'
    send recipient, text({text:txt})

    resubscribe recipient

  end



end 

