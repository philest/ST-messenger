require 'spec_helper'
require 'rack/test'
require 'timecop'
require 'active_support/time'

# require 'bot'
require 'bot/dsl'
require 'helpers/fb'
require 'workers'


describe "the scripts" do
  context "translation" do
    before(:each) do 
      allow_any_instance_of(Birdv::DSL::StoryTimeScript).to receive(:send).and_wrap_original do |original_method, *args|
        fb_id, to_send = args
        puts fb_id, to_send
      end
    end

    it "does something" do
      puts "ass"
      Birdv::DSL::ScriptClient.scripts['fb']['day1'].send "me", text({text:"hi there"})
    end

    # iterate through all the scripts
    # run process_txt on each and see if there are any fuckups
    # do the same for sms



  end




end