Birdv::DSL::ScriptClient.new_script 'remind' do
  sequence 'remind' do |recipient|
    # greeting with 5 second delay
  end

  sequence 'unsubscribe' do |recipient|
  end

  sequence 'resubscribe' do |recipient|
  end
end 


Birdv::DSL::ScriptClient.new_script 'day1' do
  sequence 'storysequence' do
    send recipient, story()
  end
end
Birdv::DSL::ScriptClient.new_script 'day2' do; end
Birdv::DSL::ScriptClient.new_script 'day3' do; end
Birdv::DSL::ScriptClient.new_script 'day4' do; end
Birdv::DSL::ScriptClient.new_script 'day5' do; end
Birdv::DSL::ScriptClient.new_script 'day6' do; end
Birdv::DSL::ScriptClient.new_script 'day7' do; end
Birdv::DSL::ScriptClient.new_script 'day8' do; end
Birdv::DSL::ScriptClient.new_script 'day9' do; end


